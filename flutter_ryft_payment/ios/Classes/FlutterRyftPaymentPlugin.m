#import <Flutter/Flutter.h>
#import "FlutterRyftPaymentPlugin.h"

@implementation FlutterRyftPaymentPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterRyftPaymentPlugin registerWithRegistrar:registrar];
}

@end 