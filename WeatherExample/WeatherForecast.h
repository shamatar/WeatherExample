//
//  WeatherForecast.h
//  WeatherExample
//
//  Created by Alexander Vlasov on 11.04.15.
//  Copyright (c) 2015 Alexander Vlasov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PresentedCities;

@interface WeatherForecast : NSManagedObject

@property (nonatomic, retain) NSNumber * averageTemperature;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) PresentedCities *presentedCity;

@end
