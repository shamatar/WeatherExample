//
//  WeatherTableViewController.m
//  WeatherExample
//
//  Created by Alexander Vlasov on 11.04.15.
//  Copyright (c) 2015 Alexander Vlasov. All rights reserved.
//

#import "WeatherTableViewController.h"
#import "WeatherDataCore.h"
#import "SearchResultsTableViewController.h"
#import "City.h"
#import "PresentedCities.h"
#import "CityPresentationCell.h"
#import "AFNetworking.h"
#import "WeatherForecast.h"
#import "DetailsViewController.h"

const NSString *APIKEY = @"8d27721d1b85de33bf7b03c7d97fd0e";

@interface WeatherTableViewController () <UISearchControllerDelegate,UISearchResultsUpdating>

@end

@implementation WeatherTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataArray = [NSMutableArray arrayWithCapacity:100];
    SearchResultsTableViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SearchResultsController"];
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:vc];
    self.searchController.searchResultsUpdater=self;
    self.searchController.delegate=self;
    self.searchController.dimsBackgroundDuringPresentation=YES;
    self.definesPresentationContext=YES;
    [self.searchController.searchBar sizeToFit];
    [self.searchController.searchBar setClipsToBounds:YES];
    self.searchController.searchBar.placeholder = @"Enter city name";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addCityToPresent:) name:@"AddCity" object:nil];
    self.manager = [AFHTTPRequestOperationManager manager];
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.refreshControl addTarget:self action:@selector(attemptRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self reloadData];
    [self attemptDataUpdate];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)attemptRefresh:(UIRefreshControl *)control{
    [self attemptDataUpdate];
    [control endRefreshing];
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.tableView.tableHeaderView=nil;
    
//    [self.tableView setContentOffset:CGPointMake(0.0, self.tableView.tableHeaderView.frame.size.height) animated:NO];
}

- (IBAction)addCity:(UIBarButtonItem *)sender {
//    self.navigationController.navigationItem.titleView = self.searchController.searchBar;
    self.tableView.tableHeaderView=self.searchController.searchBar;
    [self.searchController.searchBar becomeFirstResponder];
//    [self.navigationController.view bringSubviewToFront:self.searchBar];
//    [self.searchBar becomeFirstResponder];
}

-(void)willDismissSearchController:(UISearchController *)searchController{
    self.tableView.tableHeaderView=nil;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)reloadData{
    [self.dataArray removeAllObjects];
    NSArray *results = [[WeatherDataCore sharedInstance] entitiesForName:@"PresentedCities"];
    [self.dataArray addObjectsFromArray:results];
    [self.tableView reloadData];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.dataArray.count;
}


-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (!searchController.active){
        return;
    }
    NSString *searchString = [searchController.searchBar text];
    NSArray *results = [[WeatherDataCore sharedInstance] findCitiesMatchingString:searchString];
//    [self updateFilteredContentForProductName:searchString type:scope];
    
    if (self.searchController.searchResultsController) {
        SearchResultsTableViewController *vc = (SearchResultsTableViewController *)self.searchController.searchResultsController;
        [vc.dataArray removeAllObjects];
        if (results.count >100){
            vc.dataArray = [NSMutableArray arrayWithArray:[results subarrayWithRange:NSMakeRange(0, 100)]];
        }
        else{
            vc.dataArray = [NSMutableArray arrayWithArray:results];
        }
        [vc.tableView reloadData];
    }
    
}
-(void)addCityToPresent:(NSNotification *)object{
    City *city = object.object;
    [[WeatherDataCore sharedInstance] addCityForPresentationUsingObjectID:[city objectID]];
//    [self.searchController resignFirstResponder];
//    [self reloadData];
//    [self attemptDataUpdate];
    [self.searchController dismissViewControllerAnimated:YES completion:^{
        [self reloadData];
        [self attemptDataUpdate];
    }];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CityPresentationCell *cell = (CityPresentationCell*)[tableView dequeueReusableCellWithIdentifier:@"CityCell" forIndexPath:indexPath];
    PresentedCities *toPresent = (PresentedCities *)[self.dataArray objectAtIndex:indexPath.row];
    cell.cityName.text = toPresent.city.nameAndCountry;
    WeatherForecast *bestForecast = nil;
    NSArray *availibleForecasts =[[WeatherDataCore sharedInstance] getMostRecentForecastForPresentedCityWithObjectID:[toPresent objectID]];
    NSTimeInterval interval = 24*60*60;
    if (availibleForecasts.count>0){
        for (WeatherForecast *forecast in availibleForecasts){
            if ([[NSCalendar currentCalendar] isDateInToday:forecast.date]){
                if(fabs([forecast.date timeIntervalSinceDate:[NSDate date]]) < interval)
                {
                    interval = fabs([forecast.date timeIntervalSinceDate:[NSDate date]]);
                    bestForecast=forecast;
                }
            }
        }
    }
    if (bestForecast){
//        NSLog(@"%@",[bestForecast description]);
        cell.averageTemperature.text = [NSString stringWithFormat:@"%3.0f",[bestForecast.averageTemperature doubleValue]];
    }
    else if (availibleForecasts.count>0){
        WeatherForecast *firstAvailible = [availibleForecasts objectAtIndex:0];
        cell.averageTemperature.text = [NSString stringWithFormat:@"%3.0f",[firstAvailible.averageTemperature doubleValue]];
    }
    else{
        cell.averageTemperature.text = @"";
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PresentedCities *toDelete = [self.dataArray objectAtIndex:indexPath.row];
        [[WeatherDataCore sharedInstance] removeCityForPresentationUsingObjectID:[toDelete objectID]];
         [self.dataArray removeObject:toDelete];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
-(void)attemptDataUpdate{
    [self.manager.operationQueue cancelAllOperations];
    self.operations=0;
    self.operationsCompleted=0;
    self.operations = self.dataArray.count;
    for (PresentedCities *city in self.dataArray){
        NSDictionary *parameters = @{@"id": [NSString stringWithFormat:@"%lu",[city.city.cityID unsignedLongValue]],
                                     @"units":@"metric",
                                     @"APPID":APIKEY};
        [self addRequestOperationForCity:city AndParameters:parameters];
    }
}

-(void)addRequestOperationForCity:(PresentedCities *)city AndParameters:(NSDictionary *)parameters{
    NSMutableURLRequest *request = [self.manager.requestSerializer requestWithMethod:@"GET" URLString:@"http://api.openweathermap.org/data/2.5/weather" parameters:parameters];
    [request setTimeoutInterval:15];
    AFHTTPRequestOperation *operation = [self.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = (NSDictionary *)responseObject;
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
        id temp = dict[@"main"][@"temp"];
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
        dispatch_async(dispatch_get_main_queue(), ^{
            [[WeatherDataCore sharedInstance] createForecastForCityWithObjectID:[city objectID] Date:date Temperature:temperature];
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.dataArray indexOfObject:city] inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
            [self incrementCompleted];
        });
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", operation.responseString);
        [self addRequestOperationForCity:city AndParameters:parameters];
    }];
    [self.manager.operationQueue addOperation:operation];
}
-(void)incrementCompleted{
    self.operationsCompleted++;
    if (self.operationsCompleted == self.operations){
        if ([self.refreshControl isRefreshing]){
            [self.refreshControl endRefreshing];
        }
        [self reloadData];
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    ShowDetailsForCity
    DetailsViewController *vc = (DetailsViewController *)[segue destinationViewController];
    CityPresentationCell *cell = (CityPresentationCell *)sender;
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    PresentedCities *record = [self.dataArray objectAtIndex:path.row];
    vc.currentCity = record;
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
