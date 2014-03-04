//
//  MRCForecastCell.h
//  WeatherApp
//
//  Created by Marty Cullen on 3/3/14.
//  Copyright (c) 2014 MartyCullen.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MRCForecastCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *temperature;
@property (weak, nonatomic) IBOutlet UILabel *day;

@end
