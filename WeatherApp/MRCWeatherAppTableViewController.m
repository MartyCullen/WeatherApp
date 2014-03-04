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

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self requestTodayData];

    self.tableView.separatorColor = [self grayDarkest];
    
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
- (UIColor*) grayDarkest
{
    return [UIColor colorWithRed:23/255 green:23/255 blue:23/255 alpha:1.0];
}

- (NSDate*) safeAddDayToDate:(NSDate*)inDate
{
    // set up date components to add ONE day
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:1];
    
    // create a calendar
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate* result = [gregorian dateByAddingComponents:components toDate:inDate options:0];
    NSLog(@"Clean: %@", result);
    
    return result;
}

- (NSString*) DayOfWeek: (NSDate*)date
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"EEEE"];
    
    NSString *result = [format stringFromDate:date];
    
    return result;

}

#pragma mark - Comm Initiators
- (void) requestTodayData
{
    // Create the request.
    NSString* url = @"http://api.openweathermap.org/data/2.5/weather?q=Durham,NC&units=imperial";
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    // Create url connection and fire request
    self.todayConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void) requestForecastDataForLocation:(NSString*) locId
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
            NSLog(@"Error:%@", error);
        }
        else
        {
            self.currentCityString = [json objectForKey:@"name"];
            NSString* locId = [json objectForKey:@"id"];
            NSDictionary* main = [json objectForKey:@"main"];
            NSNumber* currentTemp = [main objectForKey:@"temp"];
            self.currentTempString = [self formatTemperature:currentTemp];
            NSLog(@"City %@   Main %@  temp %@  id %@", self.currentCityString, main, self.currentTempString, locId );
            
            [self requestForecastDataForLocation:locId];
        }
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
            NSLog(@"Error:%@", error);
        }
        else
        {
            NSArray* list = [json objectForKey:@"list"];
            NSLog(@"list %@  %d ", list, [list count] );
            NSDate* dayOfWeek = [NSDate date];
            self.forecastCellStrings = [[NSMutableArray alloc] init];
            
            for (NSDictionary* day in list) {
                // Increment the day for display
                dayOfWeek = [self safeAddDayToDate:dayOfWeek];
                
                NSDictionary* temp = [day objectForKey:@"temp"];
                NSNumber* max = [temp objectForKey:@"max"];
                NSString* temperature = [self formatTemperature:max];
                NSLog(@"max %@", temperature );
                
                // Store te results to display in the array
                NSDictionary* forecast = @{ @"temperature" : temperature, @"day" : [self DayOfWeek:dayOfWeek] };
                [self.forecastCellStrings addObject:forecast];
            }
            
            [self.tableView reloadData];
        }
    }
}




#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    
    if (connection == self.todayConnection )
    {
        self.todayData = [[NSMutableData alloc] init];
    }
    else if (connection == self.forecastConnection )
    {
        self.forecastData = [[NSMutableData alloc] init];
    }
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

    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
}


- (NSString*) formatTemperature:(NSNumber*)tempAsNumber
{
    NSInteger tempInt = tempAsNumber.integerValue;
    return [NSString stringWithFormat:@"%d°", tempInt ];
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

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
