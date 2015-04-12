//
//  DetailsViewController.m
//  WeatherExample
//
//  Created by Alexander Vlasov on 11.04.15.
//  Copyright (c) 2015 Alexander Vlasov. All rights reserved.
//

#import "DetailsViewController.h"
#import "WeatherDataCore.h"
#import "ForecastCell.h"

@interface DetailsViewController ()

@end
extern const NSString *APIKEY;
@implementation DetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataArray = [NSMutableArray arrayWithCapacity:100];
    self.manager = [AFHTTPRequestOperationManager manager];
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.refreshControl addTarget:self action:@selector(attemptDataUpdate) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0:
            self.limitToPresent=3;
            break;
        case 1:
            self.limitToPresent=7;
            break;
        default:
            break;
    }
    [self reloadData];
    [self attemptDataUpdate];
    // Do any additional setup after loading the view.
}
- (IBAction)changedSegmentedControl:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.limitToPresent=3;
            [self.tableView reloadData];
            break;
        case 1:
            self.limitToPresent=7;
            [self.tableView reloadData];
            break;
        default:
            break;
    }
}

-(void)reloadData{
    [self.dataArray removeAllObjects];
    if (self.currentCity){
        self.nameLabel.text = self.currentCity.city.nameAndCountry;
    }
    NSArray *results = [[WeatherDataCore sharedInstance] getMostRecentForecastForPresentedCityWithObjectID:[self.currentCity objectID]];
    WeatherForecast *bestForecast = nil;
    NSTimeInterval interval = 24*60*60.0;
    NSDate *now = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ) fromDate:now];
    [components setHour:-[components hour]];
    [components setMinute:-[components minute]];
    [components setSecond:-[components second]];
    NSDate *startOfToday = [cal dateByAddingComponents:components toDate:now options:0];
    [components setHour:+24];
    [components setMinute:0];
    [components setSecond:0];
    NSDate *tomorrow = [cal dateByAddingComponents:components toDate: startOfToday options:0];
    if (results.count>0){
        for (WeatherForecast *forecast in results){
            if ([[NSCalendar currentCalendar] isDateInToday:forecast.date]){
                if(fabs([forecast.date timeIntervalSinceDate:[NSDate date]]) < interval)
                {
                    interval = fabs([forecast.date timeIntervalSinceDate:[NSDate date]]);
                    bestForecast=forecast;
                }
            }
            if (([forecast.date compare:tomorrow] == NSOrderedDescending) || ([forecast.date compare:tomorrow] == NSOrderedSame)){
                [self.dataArray addObject:forecast];
            }
        }
    }
    if (bestForecast){
//        NSLog(@"%@",[bestForecast description]);
        self.recentTemperatureLabel.text = [NSString stringWithFormat:@"%3.0f",[bestForecast.averageTemperature doubleValue]];
    }
    else if (results.count>0){
        WeatherForecast *firstAvailible = [results objectAtIndex:0];
        self.recentTemperatureLabel.text = [NSString stringWithFormat:@"%3.0f",[firstAvailible.averageTemperature doubleValue]];
    }
    else{
        self.recentTemperatureLabel.text = @"";
    }
    [self.tableView reloadData];
    if ([self.refreshControl isRefreshing]){
        [self.refreshControl endRefreshing];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (self.limitToPresent <= self.dataArray.count){
        return self.limitToPresent;
    }
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ForecastCell *cell = (ForecastCell*)[tableView dequeueReusableCellWithIdentifier:@"ForecastCell" forIndexPath:indexPath];
    WeatherForecast *forecast = (WeatherForecast*)[self.dataArray objectAtIndex:indexPath.row];
    NSDateFormatter *dateFormatter =[[NSDateFormatter alloc] init];
//    NSLog(@"%@",[forecast.date description]);
    [dateFormatter setDateFormat:@"EEEE, d/MM"];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    cell.dayLabel.text = [dateFormatter stringFromDate:forecast.date];
    cell.temperatureLabel.text = [NSString stringWithFormat:@"%3.0f",[forecast.averageTemperature doubleValue]];
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)attemptDataUpdate{
    [self.manager.operationQueue cancelAllOperations];
    NSDictionary *parameters = @{@"id": [NSString stringWithFormat:@"%lu",[self.currentCity.city.cityID unsignedLongValue]],
                                     @"units":@"metric",
                                     @"APPID":APIKEY,
                                    @"cnt":@"16"};
    [self addRequestOperationForCity:self.currentCity AndParameters:parameters];
}

-(void)addRequestOperationForCity:(PresentedCities *)city AndParameters:(NSDictionary *)parameters{
    NSMutableURLRequest *request = [self.manager.requestSerializer requestWithMethod:@"GET" URLString:@"http://api.openweathermap.org/data/2.5/forecast/daily" parameters:parameters];
    [request setTimeoutInterval:15];
    AFHTTPRequestOperation *operation = [self.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateForecastsUsingDictionary:(NSDictionary *)responseObject];
        });
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", operation.responseString);
        [self addRequestOperationForCity:city AndParameters:parameters];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.refreshControl isRefreshing]){
                [self.refreshControl endRefreshing];
            }
        });
    }];
    [self.manager.operationQueue addOperation:operation];
}

-(void)updateForecastsUsingDictionary:(NSDictionary *)dictionary{
    id array = dictionary[@"list"];
    if (![array isKindOfClass:[NSArray class]]){
        return;
    }
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    formatter.maximumIntegerDigits=3;
    formatter.maximumFractionDigits=0;
    formatter.formatterBehavior=NSNumberFormatterBehaviorDefault;
    formatter.roundingMode=NSNumberFormatterRoundFloor;
    formatter.decimalSeparator=@".";
    NSNumberFormatter *dateFormatter = [[NSNumberFormatter alloc] init];
    [dateFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    dateFormatter.maximumIntegerDigits=20;
    dateFormatter.maximumFractionDigits=0;
    dateFormatter.formatterBehavior=NSNumberFormatterBehaviorDefault;
    dateFormatter.roundingMode=NSNumberFormatterRoundFloor;
    for (NSDictionary *dict in (NSArray*)array){
        id temp = dict[@"temp"][@"day"];
        NSNumber *temperature;
        if ([temp isKindOfClass:[NSNumber class]]){
            temperature=temp;
        }
        else if ([temp isKindOfClass:[NSString class]]){
            temperature = [formatter numberFromString:temp];
        }
        id dt = dict[@"dt"];
        NSDate *date;
        if ([dt isKindOfClass:[NSNumber class]]){
            date = [NSDate dateWithTimeIntervalSince1970:[dt doubleValue]];
        }
        else if ([dt isKindOfClass:[NSString class]]){
            date = [NSDate dateWithTimeIntervalSince1970:[[dateFormatter numberFromString:dt] doubleValue]];
        }
        NSLog(@"Adding record for %@",[date description]);
        [[WeatherDataCore sharedInstance] createForecastForCityWithObjectID:[self.currentCity objectID] Date:date Temperature:temperature];
    }
    [self reloadData];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
