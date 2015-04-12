//
//  AppDelegate.m
//  WeatherExample
//
//  Created by Alexander Vlasov on 11.04.15.
//  Copyright (c) 2015 Alexander Vlasov. All rights reserved.
//

#import "AppDelegate.h"
#import "WeatherDataCore.h"
#import "City.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id done = [defaults objectForKey:@"CitiesImportDone"];
    if (done!=nil){
        if (![done boolValue]){
            [self importCities];
        }
    }
    else{
        [self importCities];
    }
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"CitiesImportDone"];
    [defaults synchronize];
    
    done = [defaults objectForKey:@"FirstLaunchSetupDone"];
    if (done!=nil){
        if (![done boolValue]){
            [self doFirstLaunchSetup];
        }
    }
    else{
        [self doFirstLaunchSetup];
    }
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"FirstLaunchSetupDone"];
    [defaults synchronize];
    
    // Override point for customization after application launch.
    return YES;
}
-(void)doFirstLaunchSetup{
    NSArray *results = [[WeatherDataCore sharedInstance] findCitiesMatchingString:@"Moscow,RU"];
    [[WeatherDataCore sharedInstance] addCityForPresentationUsingObjectID:[[results objectAtIndex:0] objectID]];
    results = [[WeatherDataCore sharedInstance] findCitiesMatchingString:@"Saint Petersburg,RU"];
    [[WeatherDataCore sharedInstance] addCityForPresentationUsingObjectID:[[results objectAtIndex:0] objectID]];
}
-(void)importCities{
    NSArray *res = [[WeatherDataCore sharedInstance] entitiesForName:@"City"];
    for (City *city in res){
        [[WeatherDataCore sharedInstance] removeCityWithObjectID:[city objectID]];
    }
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *cityListPath = [bundle pathForResource:@"city_list" ofType:@"txt"];
    NSError *error=nil;
    NSString *cityListString = [NSString stringWithContentsOfFile:cityListPath encoding:NSUTF8StringEncoding error:&error];
    NSUInteger chunkSize = 100;
    NSNumberFormatter *decimalFormatter = [[NSNumberFormatter alloc] init];
    decimalFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    decimalFormatter.maximumFractionDigits=10;
    decimalFormatter.maximumIntegerDigits=3;
    NSNumberFormatter *integerFormatter = [[NSNumberFormatter alloc] init];
    integerFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    integerFormatter.maximumFractionDigits=0;
    integerFormatter.maximumIntegerDigits=10;
    NSArray *cities = [cityListString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSUInteger size = cities.count;
    NSMutableArray *processedCities = [NSMutableArray arrayWithCapacity:size];
    for (NSInteger i=0; i<(NSInteger) ceil ((double)cities.count / (double) chunkSize);i++){
        NSRange range;
        if (cities.count - i*chunkSize >= chunkSize){
            range = NSMakeRange(i*chunkSize, chunkSize);
        }
        else{
            range = NSMakeRange(i*chunkSize, cities.count - i*chunkSize-1);
        }
        NSArray *splice = [cities subarrayWithRange:range];
        for (NSString *city in splice){
            NSArray *parameters = [city componentsSeparatedByString:@"\t"];
            NSString *cityIDString = parameters[0];
            NSString *cityName = parameters[1];
            NSString *latitudeString = parameters[2];
            NSString *longitudeString = parameters[3];
            NSString *country = parameters[4];
            NSNumber *latitude = [decimalFormatter numberFromString:latitudeString];
            NSNumber *longitude = [decimalFormatter numberFromString:longitudeString];
            NSNumber *cityID = [integerFormatter numberFromString:cityIDString];
            if (cityID && latitude && longitude && (cityName.length!=0) && (country.length!=0)){
            NSDictionary *dict = @{@"name" : cityName,
                                   @"country" : country,
                                   @"latitude" :latitude,
                                   @"longitude":longitude,
                                   @"cityID":cityID,};
            [processedCities addObject:dict];
            }
            else{
                NSLog(@"Nil detected for city %@",cityName);
            }
//            [[WeatherDataCore sharedInstance] createCityWithName:cityName Country:country Latitude:latitude Longitude:longitude Index:cityID];
//            parameters=nil;
//            cityID=nil;
//            cityIDString=nil;
//            cityName=nil;
//            latitude=nil;
//            latitudeString=nil;
//            longitude=nil;
//            longitudeString=nil;
        }
//        splice=nil;
        NSLog(@"%lu",(unsigned long)i);
    }
    [[WeatherDataCore sharedInstance] importArrayOfCities:processedCities];
//    NSArray *results = [[WeatherDataCore sharedInstance] entitiesForName:@"City"];
}
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.willecome.WeatherExample" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"WeatherExample" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"WeatherExample.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
