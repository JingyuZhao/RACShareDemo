//
//  AppDelegate.m
//  RACShareDemo
//
//  Created by zhaojingyu on 2020/3/16.
//  Copyright © 2020 Shoufuyou. All rights reserved.
//

#import "AppDelegate.h"
#import "RootViewController.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    UIStoryboard*storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    RootViewController*root = [storyboard instantiateViewControllerWithIdentifier:@"RootViewController"];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:root];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}


@end
