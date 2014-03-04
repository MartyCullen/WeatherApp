//
//  MRCWeatherAppTableViewController.h
//  WeatherApp
//
//  Created by Marty Cullen on 3/3/14.
//  Copyright (c) 2014 MartyCullen.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MRCCurrentCell.h"
#import "MRCForecastCell.h"
#import "MBProgressHUD.h"

@interface MRCWeatherAppTableViewController : UITableViewController <NSURLConnectionDelegate, MBProgressHUDDelegate> {
	MBProgressHUD *HUD;
    
	long long expectedLength;
	long long currentLength;
}
@property (nonatomic, strong) NSURLConnection* todayConnection;
@property (nonatomic, strong) NSMutableData* todayData;
@property (nonatomic, strong) NSURLConnection* forecastConnection;
@property (nonatomic, strong) NSMutableData* forecastData;

@property (nonatomic, strong) NSMutableArray* forecastCellStrings;
@property (nonatomic, strong) NSString* currentTempString;
@property (nonatomic, strong) NSString* currentCityString;

@end
