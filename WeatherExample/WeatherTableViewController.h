//
//  WeatherTableViewController.h
//  WeatherExample
//
//  Created by Alexander Vlasov on 11.04.15.
//  Copyright (c) 2015 Alexander Vlasov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFNetworking.h"

@interface WeatherTableViewController : UITableViewController
@property (strong, nonatomic) NSMutableArray *dataArray;
@property (strong, nonatomic) UISearchController *searchController;
@property (assign, nonatomic) NSInteger operations;
@property (assign, nonatomic) NSInteger operationsCompleted;
@property (strong, nonatomic) AFHTTPRequestOperationManager *manager;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@end
