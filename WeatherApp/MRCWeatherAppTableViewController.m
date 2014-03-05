//
//  MRCWeatherAppTableViewController.m
//  WeatherApp
//
//  Created by Marty Cullen on 3/3/14.
//  Copyright (c) 2014 MartyCullen.com. All rights reserved.
//

#import "MRCWeatherAppTableViewController.h"

@interface MRCWeatherAppTableViewController ()

@end

@implementation MRCWeatherAppTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self startEvent];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Utils
- (NSDate*) safeAddDayToDate:(NSDate*)inDate
{
    // set up date components to add ONE day
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:1];
    
    // create a calendar
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate* result = [gregorian dateByAddingComponents:components toDate:inDate options:0];
    //NSLog(@"Date: %@", result);
    
    return result;
}

- (NSString*) DayOfWeek: (NSDate*)date
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"EEEE"];
    
    NSString *result = [format stringFromDate:date];
    
    return result;

}

- (NSString*) formatTemperature:(NSNumber*)tempAsNumber
{
    NSInteger tempInt = tempAsNumber.integerValue;
    return [NSString stringWithFormat:@"%d°", tempInt ];
}

- (void) errorHandler:(NSError*)error forArea:(NSString*)area
{
    // TODO: Enhance Error Handler
    NSLog(@"%@ Error:%@", area, error);
    _gotError = YES;
    [self eventManager];
    
    if ( [area isEqualToString:ERROR_AREA_LOCATION] && kCLErrorDomain == error.domain && 0 == error.code  )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Services Error" message:@"Unable to use location services." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Misc Error" message:error.domain delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
}


- (void) startEvent
{
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.dimBackground = YES;
    HUD.delegate = self;

    [self findCurrentLocation];

}

- (void) eventManager
{
    // TODO: Look into Reactive Cocoa instead of daisy chaining lookups
    // http://www.raywenderlich.com/55386/ios-7-best-practices-part-2
    
    // TODO: Maybe add timer to timeout HUD and fail?
    
    if ( _gotError )
    {
        [HUD hide:YES];
        return;
    }
    NSLog(@"No Error");
    
    if ( !self.currentTempString )
        return;
    NSLog(@"Got Current");
    
    if ( !self.forecastCellStrings )
        return;
    NSLog(@"Got Forecast");
    
    if ( !self.currentCityString )
        return;
    NSLog(@"Got City");
    
    // If we have everything, reload and remove the HUD
    [self.tableView reloadData];
    [HUD hide:YES];
}

#pragma mark - Core Location
//+ (instancetype)sharedManager {
//    static id _sharedManager = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        _sharedManager = [[self alloc] init];
//    });
//    
//    return _sharedManager;
//}

- (void)findCurrentLocation {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    self.isFirstUpdate = YES;
    [self.locationManager startUpdatingLocation];
}

- (void) reverseGeocode
{
    if ( self.currentLocation )
    {
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        
        [geocoder reverseGeocodeLocation:self.currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
            if (error){
                [self errorHandler:error forArea:@"GeoCoder"];
                return;
            }
            //NSLog(@"Received placemarks: %@", placemarks);
            
            //[self displayPlacemarks:placemarks];
            CLPlacemark* placemark = [placemarks lastObject];
            self.currentCityString = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.administrativeArea];
            //NSLog(@"City: %@", self.currentCityString);
            
            // Notify Event Manager, see if we have everything
            [self eventManager];
        }];
    }
}


#pragma mark - Comm Initiators
- (void) requestTodayData
{
    // We need la location
    if ( self.currentLocation )
    {
        // Once started, igore subsequent requests (While locationManager shuts down)
        if ( !self.todayConnection )
        {
            // Create the request.
            CLLocationDegrees lat = self.currentLocation.coordinate.latitude;
            CLLocationDegrees lon = self.currentLocation.coordinate.longitude;
            NSString* url = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&units=imperial", lat, lon];
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
            
            // Create url connection and fire request
            self.todayConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        }
    }
}

- (void) requestForecastDataForLocationId:(NSString*) locId
{
    // Create the request.
    NSString* url = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast/daily?id=%@&units=imperial&cnt=5", locId];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    // Create url connection and fire request
    self.forecastConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

#pragma mark - JSON Parsers
- (void) processTodayData
{
    if ( self.todayData )
    {
        //parse out the json data
        NSError* error;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:self.todayData
                              options:kNilOptions
                              error:&error];
        //NSLog(@"TODAY Json \n %@", json );
        
        if ( error )
        {
            [self errorHandler:error forArea:@"Current Contitions"];
        }
        else
        {
            //self.currentCityString = [json objectForKey:@"name"];
            NSString* locId = [json objectForKey:@"id"];
            NSDictionary* main = [json objectForKey:@"main"];
            NSNumber* currentTemp = [main objectForKey:@"temp"];
            self.currentTempString = [self formatTemperature:currentTemp];
            //NSLog(@"City %@   Main %@  temp %@  id %@", self.currentCityString, main, self.currentTempString, locId );
            
            [self requestForecastDataForLocationId:locId];
            
            // Notify Event Manager, see if we have everything
            [self eventManager];
        }
        
        self.todayConnection = nil;
        self.todayData = nil;
    }
}

- (void) processForecastData
{
    if ( self.forecastData )
    {
        //parse out the json data
        NSError* error;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:self.forecastData
                              options:kNilOptions
                              error:&error];
        //NSLog(@"FORECAST Json \n %@", json );
        
        if ( error )
        {
            [self errorHandler:error forArea:@"Forecast"];
        }
        else
        {
            NSArray* list = [json objectForKey:@"list"];
            //NSLog(@"list %@  %d ", list, [list count] );
            NSDate* dayOfWeek = [NSDate date];
            self.forecastCellStrings = [[NSMutableArray alloc] init];
            
            for (NSDictionary* day in list) {
                // Increment the day for display
                dayOfWeek = [self safeAddDayToDate:dayOfWeek];
                
                NSDictionary* temp = [day objectForKey:@"temp"];
                NSNumber* max = [temp objectForKey:@"max"];
                NSString* temperature = [self formatTemperature:max];
                //NSLog(@"max %@", temperature );
                
                // Store te results to display in the array
                NSDictionary* forecast = @{ @"temperature" : temperature, @"day" : [self DayOfWeek:dayOfWeek] };
                [self.forecastCellStrings addObject:forecast];
            }
            
            // Notify Event Manager, see if we have everything
            [self eventManager];
        }
        
        self.forecastConnection = nil;
        self.forecastData = nil;
        //NSLog(@"Got All Weather");
    }
}




#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    if (self.isFirstUpdate) {
        self.isFirstUpdate = NO;
        return;
    }
    
    CLLocation *location = [locations lastObject];
    
    if (location.horizontalAccuracy > 0) {
        self.currentLocation = location;
        //NSLog(@"Current Location Found: %@", location);
        // Shut down the GPS search
        [self.locationManager stopUpdatingLocation];
        
        // Lookup the state for this location
        [self reverseGeocode];
        
        // Lookup the current weather for this location
        [self requestTodayData];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self errorHandler:error forArea:ERROR_AREA_LOCATION];
    //[HUD hide:YES];
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
	//expectedLength = MAX([response expectedContentLength], 1);
	//currentLength = 0;
    
    if (connection == self.todayConnection )
    {
        self.todayData = [[NSMutableData alloc] init];
    }
    else if (connection == self.forecastConnection )
    {
        self.forecastData = [[NSMutableData alloc] init];
    }
    
    //HUD.mode = MBProgressHUDModeDeterminate;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    if (connection == self.todayConnection && self.todayData )
    {
        [self.todayData appendData:data];
    }
    else if (connection == self.forecastConnection && self.forecastData)
    {
        [self.forecastData appendData:data];
    }
    //currentLength += [data length];
	//HUD.progress = currentLength / (float)expectedLength;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    
    if (connection == self.todayConnection )
    {
        [self processTodayData];
    }
    else if (connection == self.forecastConnection )
    {
        [self processForecastData];
    }
	//[HUD hide:YES];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    [self errorHandler:error forArea:@"Connection"];
    //[HUD hide:YES];

}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = nil;
    if ( 0 == indexPath.row ) {
        cell = [self tableView:tableView currentCell:indexPath];
    } else {
        cell = [self tableView:tableView futureCell:indexPath];
    
    }
    return cell;
}

- (UITableViewCell*)tableView:(UITableView *)tableView currentCell:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"current";
    MRCCurrentCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    if ( self.currentCityString )
    {
        cell.city.text = self.currentCityString;
    }
    if ( self.currentTempString )
    {
        cell.temperature.text = self.currentTempString;
    }
    return cell;
    
}

- (UITableViewCell*)tableView:(UITableView *)tableView futureCell:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"future";
    MRCForecastCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if ( [self.forecastCellStrings count] > indexPath.row - 1 && indexPath.row > 0 )
    {
        NSDictionary* forecast = [self.forecastCellStrings objectAtIndex:indexPath.row - 1];
        NSString* temperature = [forecast objectForKey:@"temperature"];
        NSString* day = [forecast objectForKey:@"day"];
        if ( temperature )
        {
            cell.temperature.text = temperature;
        }
        if ( day )
        {
            cell.day.text = day;
        }
    }
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Cells are 75 except first one
    CGFloat height = 75.0;
    if ( 0 == indexPath.row ) {
        height = 162.0;
    }
    
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    // Manually build the header
    UIView* cell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
    cell.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:0.95];
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 32, 320, 20)];
    label.text = @"Weather App";
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"Avenir-Book" size:20.0];
    
    [cell addSubview:label];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 64.0;
}

#pragma mark - MBProgressHUDDelegate methods
- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	[HUD removeFromSuperview];
	HUD = nil;
}

@end
