//
//  WeatherDataCore.m
//  WeatherExample
//
//  Created by Alexander Vlasov on 11.04.15.
//  Copyright (c) 2015 Alexander Vlasov. All rights reserved.
//

#import "WeatherDataCore.h"
#import "City.h"
#import "WeatherForecast.h"
#import "PresentedCities.h"

@implementation WeatherDataCore

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.willecome.RSSReaderExample" in the application's documents directory.
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

-(NSArray*)entitiesForName:(NSString *)name{
    if (name.length!=0){
        NSManagedObjectContext *context = [self managedObjectContext];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:name inManagedObjectContext:context];
        [request setEntity:entity];
        NSError *error = nil;
        NSArray *results = [context executeFetchRequest:request error:&error];
        if (error){
            NSLog(@"Error fetching entities: %@\n%@", [error localizedDescription], [error userInfo]);
            return nil;
        }
        return results;
    }
    return nil;
}
-(BOOL)addCityForPresentationUsingObjectID:(NSManagedObjectID *)objectID{
    BOOL success = NO;
    NSManagedObjectContext *context = [self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"PresentedCities" inManagedObjectContext:context];
    if (objectID){
        PresentedCities *new = [[PresentedCities alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
        new.city = (City *)[context objectWithID:objectID];
        new.presentationOrder = [WeatherDataCore nextAvailble:@"presentationOrder" forEntityName:@"PresentedCities" inContext:context];
        [self saveContext];
        success=YES;
    }
    return success;
}

-(BOOL)removeCityForPresentationUsingObjectID:(NSManagedObjectID *)objectID{
    BOOL success = NO;
    NSManagedObjectContext *context = [self managedObjectContext];
    if (objectID){
        PresentedCities *toDelete = (PresentedCities*)[context objectWithID:objectID];
        [context deleteObject:toDelete];
        [self saveContext];
        success=YES;
    }
    return success;
}

-(BOOL)createCityWithName:(NSString *)name Country:(NSString *)country Latitude:(NSNumber *)latitude Longitude:(NSNumber *)longitude Index:(NSNumber *)index {
    BOOL success = NO;
    if ((name.length!=0) && (country.length!=0) && (latitude!=nil) && (longitude!=nil) && (index!=nil)){
        NSManagedObjectContext *context = [self managedObjectContext];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"City" inManagedObjectContext:context];
        City *new = [[City alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
        new.nameAndCountry = [NSString stringWithFormat:@"%@,%@",[name capitalizedString],[country uppercaseString]];
        new.cityID = index;
        new.latitude=latitude;
        new.longitude=longitude;
        [self saveContext];
        success=YES;
    }
    return success;
}

-(BOOL)removeCityWithObjectID:(NSManagedObjectID*)objectID{
    BOOL success = NO;
    if ((objectID!=nil)){
        NSManagedObjectContext *context = [self managedObjectContext];
        City *toDelete = (City *)[context objectRegisteredForID:objectID];
        if (toDelete!=nil){
            [context deleteObject:toDelete];
            [self saveContext];
            success=YES;
        }
    }
    return success;
}

-(BOOL)importArrayOfCities:(NSArray *)array{
    BOOL success = NO;
    for (NSDictionary *city in array){
        NSString *name = [city objectForKey:@"name"];
        NSString *country = [city objectForKey:@"country"];
        NSNumber *cityID = [city objectForKey:@"cityID"];
        NSNumber *latitude = [city objectForKey:@"latitude"];
        NSNumber *longitude = [city objectForKey:@"longitude"];
        NSManagedObjectContext *context = [self managedObjectContext];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"City" inManagedObjectContext:context];
        if ((name.length!=0) && (country.length!=0) && (latitude!=nil) && (longitude!=nil) && (cityID!=nil)){
            City *new = [[City alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
            new.nameAndCountry = [NSString stringWithFormat:@"%@,%@",[name capitalizedString],[country uppercaseString]];
            new.cityID = cityID;
            new.latitude=latitude;
            new.longitude=longitude;
        }
    }
    [self saveContext];
    success=YES;
    return success;
}

-(BOOL)createForecastForCityWithObjectID:(NSManagedObjectID *)objectID Date:(NSDate *)date Temperature:(NSNumber *)temperature{
    BOOL success = NO;
    if ((objectID!=nil) && (date!=nil) && (temperature!=nil)){
        NSManagedObjectContext *context = [self managedObjectContext];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"WeatherForecast" inManagedObjectContext:context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDescription];
        NSError *error = nil;
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDate *now = [NSDate date];
        NSDateComponents *components = [cal components:( NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ) fromDate:date];
        [components setHour:-[components hour]];
        [components setMinute:-[components minute]];
        [components setSecond:-[components second]];
        NSDate *startOfToday = [cal dateByAddingComponents:components toDate:date options:0];
        [components setHour:-24];
        [components setMinute:0];
        [components setSecond:0];
        NSDate *yesterday = [cal dateByAddingComponents:components toDate: startOfToday options:0];
        [components setHour:+24];
        [components setMinute:0];
        [components setSecond:0];
        NSDate *tomorrow = [cal dateByAddingComponents:components toDate: startOfToday options:0];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(date >= %@) AND (date < %@) AND (presentedCity == %@)", startOfToday,tomorrow,[context objectWithID:objectID]];
//        NSPredicate *weakPredicate = [NSPredicate predicateWithFormat:@"(presentedCity == %@)",[context objectWithID:objectID]];
//        [request setPredicate:weakPredicate];
        [request setPredicate:predicate];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
        NSArray *results = [context executeFetchRequest:request error:&error];
        if (error){
            NSLog(@"Error fetching entities: %@\n%@", [error localizedDescription], [error userInfo]);
            return nil;
        }
//        if (results.count>0){
//            for (WeatherForecast *forecast in results){
//                NSLog(@"Deleting outdated for todat");
//                [context deleteObject:forecast];
//            }
//        }
//
//        results = [context executeFetchRequest:request error:&error];
        if ((results.count>0) && (![cal isDate:date inSameDayAsDate:now])){
            for (WeatherForecast *forecast in results){
                NSLog(@"Deleting duplicate record for %@", [date description]);
                [context deleteObject:forecast];
            }
        }
        [self saveContext];
        WeatherForecast *new = [[WeatherForecast alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
        new.date = date;
        new.averageTemperature = temperature;
        new.presentedCity = (PresentedCities *)[context objectWithID:objectID];
        [self saveContext];
        success=YES;
    }
    return success;
}
-(NSArray *)getMostRecentForecastForPresentedCityWithObjectID:(NSManagedObjectID *)objectID{
    NSArray *results = nil;
    [self removeOutdatedForecastsForPresentedCityWithObjectID:objectID];
    if (objectID!=nil){
        NSCalendar *cal = [NSCalendar currentCalendar];
                NSDate *now = [NSDate date];
        NSDateComponents *components = [cal components:( NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ) fromDate:now];
        [components setHour:-[components hour]];
        [components setMinute:-[components minute]];
        [components setSecond:-[components second]];
        NSDate *startOfToday = [cal dateByAddingComponents:components toDate:now options:0];
        NSManagedObjectContext *context = [self managedObjectContext];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"WeatherForecast" inManagedObjectContext:context];
        [request setEntity:entity];
        NSError *error = nil;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(date >= %@) AND (presentedCity == %@)", startOfToday,[context objectWithID:objectID]];
        [request setPredicate:predicate];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
        results = [context executeFetchRequest:request error:&error];
        if (error){
            NSLog(@"Error fetching entities: %@\n%@", [error localizedDescription], [error userInfo]);
            return nil;
        }
    }
    return results;
}

-(BOOL)removeOutdatedForecastsForPresentedCityWithObjectID:(NSManagedObjectID *)objectID{
    BOOL success = NO;
    if (objectID!=nil){
        NSManagedObjectContext *context = [self managedObjectContext];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"WeatherForecast" inManagedObjectContext:context];
        [request setEntity:entity];
        NSError *error = nil;
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *components = [cal components:( NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ) fromDate:[[NSDate alloc] init]];
        [components setHour:-[components hour]];
        [components setMinute:-[components minute]];
        [components setSecond:-[components second]];
        NSDate *startOfToday = [cal dateByAddingComponents:components toDate:[[NSDate alloc] init] options:0];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(date < %@) AND (presentedCity == %@)", startOfToday,[context objectWithID:objectID]];
        [request setPredicate:predicate];
        NSArray *results = [context executeFetchRequest:request error:&error];
        if (error){
            NSLog(@"Error fetching entities: %@\n%@", [error localizedDescription], [error userInfo]);
        }
        for (WeatherForecast *forecast in results){
            [context deleteObject:forecast];
        }
        [self saveContext];
        success = YES;
    }
    return success;
}


-(NSArray*)findCitiesMatchingString:(NSString *)string{
    if (string.length!=0){
        NSManagedObjectContext *context = [self managedObjectContext];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"City" inManagedObjectContext:context];
        [request setEntity:entity];
        NSError *error = nil;
        NSString *attributeName  = @"nameAndCountry";
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K contains[cd] %@",attributeName,string];
        [request setPredicate:predicate];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"nameAndCountry" ascending:YES]];
        NSArray *results = [context executeFetchRequest:request error:&error];
        if (error){
            NSLog(@"Error fetching entities: %@\n%@", [error localizedDescription], [error userInfo]);
            return nil;
        }
        return results;
    }
    return nil;
}

+(NSNumber *)nextAvailble:(NSString *)idKey forEntityName:(NSString *)entityName inContext:(NSManagedObjectContext *)context{
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = context;
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:moc];
    [request setEntity:entity];
    // [request setFetchLimit:1];
    
    NSArray *propertiesArray = [[NSArray alloc] initWithObjects:idKey, nil];
    [request setPropertiesToFetch:propertiesArray];
    
    NSSortDescriptor *indexSort = [[NSSortDescriptor alloc] initWithKey:idKey ascending:YES];
    NSArray *array = [[NSArray alloc] initWithObjects:indexSort, nil];
    [request setSortDescriptors:array];
    
    NSError *error = nil;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    // NSSLog(@"Autoincrement fetch results: %@", results);
    NSManagedObject *maxIndexedObject = [results lastObject];
    if (error) {
        NSLog(@"Error fetching index: %@\n%@", [error localizedDescription], [error userInfo]);
    }
    //NSAssert3(error == nil, @"Error fetching index: %@\n%@", [error localizedDescription], [error userInfo]);
    
    NSInteger myIndex = 1;
    if (maxIndexedObject) {
        myIndex = [[maxIndexedObject valueForKey:idKey] integerValue] + 1;
    }
    
    return [NSNumber numberWithInteger:myIndex];
}

+(instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    static WeatherDataCore *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

@end
