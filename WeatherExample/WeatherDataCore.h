//
//  WeatherDataCore.h
//  WeatherExample
//
//  Created by Alexander Vlasov on 11.04.15.
//  Copyright (c) 2015 Alexander Vlasov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@interface WeatherDataCore : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
+ (instancetype)sharedInstance;
+(NSNumber *)nextAvailble:(NSString *)idKey forEntityName:(NSString *)entityName inContext:(NSManagedObjectContext *)context;

-(NSArray*)entitiesForName:(NSString *)name;
-(NSArray*)findCitiesMatchingString:(NSString *)string;


-(BOOL)createCityWithName:(NSString *)name Country:(NSString *)country Latitude:(NSNumber *)latitude Longitude:(NSNumber *)longitude Index:(NSNumber *)index;
-(BOOL)removeCityWithObjectID:(NSManagedObjectID*)objectID;
-(BOOL)importArrayOfCities:(NSArray *)array;


-(BOOL)addCityForPresentationUsingObjectID:(NSManagedObjectID *)objectID;
-(BOOL)removeCityForPresentationUsingObjectID:(NSManagedObjectID *)objectID;

-(BOOL)createForecastForCityWithObjectID:(NSManagedObjectID *)objectID Date:(NSDate *)date Temperature:(NSNumber *)temperature;
-(NSArray *)getMostRecentForecastForPresentedCityWithObjectID:(NSManagedObjectID *)objectID;
-(BOOL)removeOutdatedForecastsForPresentedCityWithObjectID:(NSManagedObjectID *)objectID;


@end
