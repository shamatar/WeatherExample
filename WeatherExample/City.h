//
//  City.h
//  WeatherExample
//
//  Created by Alexander Vlasov on 11.04.15.
//  Copyright (c) 2015 Alexander Vlasov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface City : NSManagedObject

@property (nonatomic, retain) NSNumber * cityID;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * nameAndCountry;

@end
