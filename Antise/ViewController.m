//
//  ViewController.m
//  Antise
//
//  Created by zhaoqin on 6/16/16.
//  Copyright © 2016 Muggins. All rights reserved.
//

#import "ViewController.h"
#import "ReactiveCocoa.h"
#import "MPBluetoothKit.h"
#import <CoreBluetooth/CoreBluetooth.h>

static NSString *SERVICE_UUID = @"180D";
static NSString *CHARACTERISTIC_UUID = @"2A37";
static NSInteger TRANSFER_LENGTH = 20;
static NSInteger TRANSFER_UNIT = 2;

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *peripheral;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    [self bindViewModel];
}

- (void)bindViewModel {
    
    @weakify(self)
    [[self.scanButton rac_signalForControlEvents:UIControlEventTouchUpInside]
    subscribeNext:^(id x) {
        @strongify(self)
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }];
    
//    UIView *view = [UIView alloc] initWithFrame:cgre
    
}

#pragma mark - Bluetooth Delegates

//判断蓝牙状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]
                                                   options:nil];
        NSLog(@"CBCentralManagerStatePoweredOn");
    }
    else {
        NSLog(@"CBCentralManagerStatePoweredOff");
    }
}

//发现指定设备之后连接
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"peripheral name %@ id %@ rssi %ld", peripheral.name, peripheral.identifier, (long)[RSSI integerValue]);
    //保持对象的引用，否则会因为没有引用计数被回收
    self.peripheral = peripheral;
    [self.centralManager connectPeripheral:peripheral options:nil];
}

//连接外围设备之后读取
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]];
}

//读取特定的服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CHARACTERISTIC_UUID]] forService:service];
    }
}

//读取服务中的特征值
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]]) {
            // If it is, subscribe to it
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

/** This callback lets us know more data has arrived via notification on the characteristic
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    [self parseTransferData:characteristic.value];
}

- (void)parseTransferData:(NSData*)data {
    
    int pos = 0;
    while (pos < TRANSFER_LENGTH)  {
        // get a int from the i th range
        int intval = 0;
        if (TRANSFER_UNIT == 1) {
            [data getBytes:&intval range:NSMakeRange(pos, TRANSFER_UNIT)];
        }else {
            uint16_t ct = 0;
            [data getBytes:&ct range:NSMakeRange(pos, TRANSFER_UNIT)];
            
            intval = ((ct << 8)&0xff00) | (ct >> 8);
            //NSLog(@"before %d, after %d", ct, intval);
        }
        pos += TRANSFER_UNIT;
        NSLog(@"%d", intval);
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
