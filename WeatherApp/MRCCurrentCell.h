//
//  MRCCurrentCell.h
//  WeatherApp
//
//  Created by Marty Cullen on 3/3/14.
//  Copyright (c) 2014 MartyCullen.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MRCCurrentCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *temperature;
@property (weak, nonatomic) IBOutlet UILabel *city;

@end
