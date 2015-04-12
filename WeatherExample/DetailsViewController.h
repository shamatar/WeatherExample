//
//  DetailsViewController.h
//  WeatherExample
//
//  Created by Alexander Vlasov on 11.04.15.
//  Copyright (c) 2015 Alexander Vlasov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PresentedCities.h"
#import "City.h"
#import "WeatherForecast.h"
#import "AFNetworking.h"

@interface DetailsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *recentTemperatureLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (assign, nonatomic) NSInteger limitToPresent;
@property (strong, nonatomic) AFHTTPRequestOperationManager *manager;
@property (strong, nonatomic) PresentedCities *currentCity;
@property (strong, nonatomic) NSMutableArray *dataArray;
@property (strong, nonatomic) WeatherForecast *currentForecast;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@end
