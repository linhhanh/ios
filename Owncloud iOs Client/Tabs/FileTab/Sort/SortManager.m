//
//  SortManager.m
//  Owncloud iOs Client
//
//  Created by María Rodríguez on 03/03/16.
//
//

#import "Customization.h"
#import "SortManager.h"
#import "UIColor+Constants.h"


@implementation SortManager

#pragma mark - TableView methods
+ (NSInteger)numberOfSectionsInTableViewWithFolderList: (NSArray *)currentDirectoryArray{
    
    //If the _currentDirectoryArray doesn't have object it will have one section
    NSInteger sections = 1;
    
    if([currentDirectoryArray count] > 0){
        
        if ([ManageUsersDB getSortingWayByUserDto:[ManageUsersDB getActiveUser]] == sortByName) {
            sections = [[[UILocalizedIndexedCollation currentCollation] sectionTitles] count];
        }
        else{
            sections = currentDirectoryArray.count;
        }
    }
    return sections;
}

// Returns the table view managed by the controller object.
+ (NSInteger)numberOfRowsInSection: (NSInteger) section withCurrentDirectoryArray:(NSArray *)currentDirectoryArray andSortedArray: (NSArray *) sortedArray needsExtraEmptyRow:(BOOL) emptyMessageRow
{
    NSInteger rows = 0;
    
    if([currentDirectoryArray count] > 0 && [self getUserSortingType] == sortByName){
        rows = [[sortedArray objectAtIndex:section] count];
    }
    
    else{
        //If the _currentDirectoryArray is empty it will have one extra row to show a message in FilesViewController and SimpleFileListTableViewController. If no alphabetical order is required will also be used one row for each section for usual contents
        if (([currentDirectoryArray count] == 0 && emptyMessageRow) || ([currentDirectoryArray count] > 0 && [self getUserSortingType] == sortByModificationDate)) {
            rows = 1;
        }
    }
    return rows;
}

// Returns the table view managed by the controller object.
+ (NSString *)titleForHeaderInTableViewSection:(NSInteger)section withCurrentDirectoryArray:(NSArray *)currentDirectoryArray andSortedArray: (NSArray *) sortedArray

{
    if([self getUserSortingType] == sortByName){
        //Only show the section title if there are rows in it
        BOOL showSection = [[sortedArray objectAtIndex:section] count] != 0;
        NSArray *titles = [[UILocalizedIndexedCollation currentCollation] sectionTitles];
        
        if(k_minimun_files_to_show_separators > [currentDirectoryArray count]) {
            showSection = NO;
        }
        return (showSection) ? [titles objectAtIndex:section] : nil;}
    else return nil;
}

// Returns the titles for the sections for a table view.
+ (NSArray *)sectionIndexTitlesForTableView: (UITableView*) tableView WithCurrentDirectoryArray:(NSArray*)currentDirectoryArray{
    
    if(k_minimun_files_to_show_separators < [currentDirectoryArray count] && [SortManager getUserSortingType] == sortByName) {
        tableView.sectionIndexColor = [UIColor colorOfSectionIndexColorFileList];
        return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
    } else {
        return nil;
    }
}

#pragma mark - Array sorting methods
/*
 * Method that sorts alphabetically array by selector
 *@array -> array of sections and rows of tableview
 */
+ (NSMutableArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector {
    
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    
    NSInteger sectionCount = [[collation sectionTitles] count]; //section count is take from sectionTitles and not sectionIndexTitles
    NSMutableArray *unsortedSections = [NSMutableArray arrayWithCapacity:sectionCount];
    
    //create an array to hold the data for each section
    for(int i = 0; i < sectionCount; i++) {
        [unsortedSections addObject:[NSMutableArray array]];
    }
    //put each object into a section
    for (id object in array) {
        NSInteger index = [collation sectionForObject:object collationStringSelector:selector];
        [[unsortedSections objectAtIndex:index] addObject:object];
    }
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:sectionCount];
    
    //sort each section
    for (NSMutableArray *section in unsortedSections) {
        [sections addObject:[collation sortedArrayFromArray:section collationStringSelector:selector]];
    }
    return sections;
}

/*
 * This method sorts an array by modification Date and configure ot to be used in file lists
 */
+ (NSMutableArray*) sortByModificationDate:(NSArray*)array {
    
    DLog(@"sortByModificationDate");
    NSSortDescriptor *descriptor=[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    NSArray *descriptors=[NSArray arrayWithObject: descriptor];
    array = [array sortedArrayUsingDescriptors:descriptors];
    
    // an array with another array is needed to follow alphabetical sorting mode
    NSMutableArray *sortedArrayWithArray = [[NSMutableArray alloc]init];
    
    for (int i=0; i<array.count; i++) {
        [sortedArrayWithArray addObject:[NSArray arrayWithObject:array[i]]];
    }
    
    return sortedArrayWithArray;
}

/*
 * This method sorts an array to be shown in the files/folders list
 */
+ (NSMutableArray*) getSortedArrayFromCurrentDirectoryArray:(NSArray*) currentDirectoryArray {
    
    NSMutableArray * sortedArray = [[NSMutableArray alloc] init];
    
    switch ([self getUserSortingType]) {
        case sortByName:
            sortedArray = [self partitionObjects: currentDirectoryArray collationStringSelector:@selector(fileName)];
            break;
        case sortByModificationDate:
            sortedArray = [self sortByModificationDate:currentDirectoryArray];
            break;
            
        default:
            break;
    }
    
    return sortedArray;
}

# pragma -mark Data Base
+ (enumSortingType) getUserSortingType{
    return [ManageUsersDB getSortingWayByUserDto:[ManageUsersDB getActiveUser]];
}

@end