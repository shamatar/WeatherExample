//
//  PresentedCities.h
//  WeatherExample
//
//  Created by Alexander Vlasov on 11.04.15.
//  Copyright (c) 2015 Alexander Vlasov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class City, WeatherForecast;

@interface PresentedCities : NSManagedObject

@property (nonatomic, retain) NSNumber * presentationOrder;
@property (nonatomic, retain) NSOrderedSet *forecasts;
@property (nonatomic, retain) City *city;
@end

@interface PresentedCities (CoreDataGeneratedAccessors)

- (void)insertObject:(WeatherForecast *)value inForecastsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromForecastsAtIndex:(NSUInteger)idx;
- (void)insertForecasts:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeForecastsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInForecastsAtIndex:(NSUInteger)idx withObject:(WeatherForecast *)value;
- (void)replaceForecastsAtIndexes:(NSIndexSet *)indexes withForecasts:(NSArray *)values;
- (void)addForecastsObject:(WeatherForecast *)value;
- (void)removeForecastsObject:(WeatherForecast *)value;
- (void)addForecasts:(NSOrderedSet *)values;
- (void)removeForecasts:(NSOrderedSet *)values;
@end
