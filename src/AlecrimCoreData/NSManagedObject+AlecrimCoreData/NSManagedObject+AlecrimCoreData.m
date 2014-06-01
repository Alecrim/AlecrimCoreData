//
//  NSManagedObject+AlecrimCoreData.m
//  Imagem
//
//  Created by Vanderlei Martinelli on 15/10/13.
//  Copyright (c) 2013 Alecrim. All rights reserved.
//

#import "NSManagedObject+AlecrimCoreData.h"

#define kAlecrimCoreDataDefaultFetchBatchSize 20

@implementation NSManagedObject (AlecrimCoreData)

#pragma mark - public methods - info

+ (NSString *)entityName
{
    //return NSStringFromClass([self class]);
    return [NSStringFromClass([self class]) substringFromIndex:8];
}

#pragma mark - public methods - create

+ (instancetype)createInContext:(NSManagedObjectContext *)context
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:context];
}

#pragma mark - public methods - truncate

+ (void)truncateAllInContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [self requestAllWithPredicate:nil sortedBy:nil ascending:YES inContext:context];
    [fetchRequest setReturnsObjectsAsFaults:YES];
    [fetchRequest setIncludesPropertyValues:NO];
    
    __block NSArray *results = nil;
    __typeof(context) __weak weakContext = context;
    [context performBlockAndWait:^{
        __typeof(weakContext) __strong strongContext = weakContext;
        if (strongContext == nil)
        {
            return;
        }
        
        NSError *error = nil;
        results = [strongContext executeFetchRequest:fetchRequest error:&error];
    }];

    
    for (NSManagedObject *objectToDelete in results)
    {
        [objectToDelete deleteInContext:context];
    }
}

#pragma mark - public methods - find

+ (instancetype)findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context
{
    return [self findFirstByAttribute:attribute withValue:searchValue sortedBy:nil ascending:YES inContext:context];
}

+ (instancetype)findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", attribute, searchValue];
    return [self findFirstWithPredicate:predicate sortedBy:sortTerm ascending:ascending inContext:context];
}

+ (instancetype)findFirstWithPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context
{
    return [self findFirstWithPredicate:predicate sortedBy:nil ascending:YES inContext:context];
}

+ (instancetype)findFirstWithPredicate:(NSPredicate *)predicate sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [self requestAllWithPredicate:predicate sortedBy:sortTerm ascending:ascending fetchLimit:1 inContext:context];
    
    __block NSArray *results = nil;
    
    __typeof(context) __weak weakContext = context;
    [context performBlockAndWait:^{
        __typeof(weakContext) __strong strongContext = weakContext;
        if (strongContext == nil)
        {
            return;
        }
        
        NSError *error = nil;
        results = [strongContext executeFetchRequest:fetchRequest error:&error];
    }];
    
    if (results == nil || [results count] == 0)
    {
        return nil;
    }
    
    return [results firstObject];
}

+ (NSArray *)findAllInContext:(NSManagedObjectContext *)context
{
    return [self findAllWithPredicate:nil sortedBy:nil ascending:YES inContext:context];
}

+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
    return [self findAllWithPredicate:nil sortedBy:sortTerm ascending:ascending inContext:context];
}

+ (NSArray *)findAllWithPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context
{
    return [self findAllWithPredicate:predicate sortedBy:nil ascending:YES inContext:context];
}

+ (NSArray *)findAllWithPredicate:(NSPredicate *)predicate sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [self requestAllWithPredicate:predicate sortedBy:sortTerm ascending:ascending inContext:context];
    
    __block NSArray *results = nil;
    
    __typeof(context) __weak weakContext = context;
    [context performBlockAndWait:^{
        __typeof(weakContext) __strong strongContext = weakContext;
        if (strongContext == nil)
        {
            return;
        }
        
        NSError *error = nil;
        results = [strongContext executeFetchRequest:fetchRequest error:&error];
    }];
    
    return results;
}

#if VM_TARGET_IOS

#pragma mark - fetch

+ (NSFetchedResultsController *)fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending delegate:(id<NSFetchedResultsControllerDelegate>)delegate inContext:(NSManagedObjectContext *)context
{
    return [self fetchAllWithPredicate:nil sortedBy:sortTerm ascending:ascending groupBy:nil delegate:delegate inContext:context];
}

+ (NSFetchedResultsController *)fetchAllWithPredicate:(NSPredicate *)predicate sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending delegate:(id<NSFetchedResultsControllerDelegate>)delegate inContext:(NSManagedObjectContext *)context
{
    return [self fetchAllWithPredicate:predicate sortedBy:sortTerm ascending:ascending groupBy:nil delegate:delegate inContext:context];
}

+ (NSFetchedResultsController *)fetchAllWithPredicate:(NSPredicate *)predicate sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending groupBy:(NSString *)groupingKeyPath delegate:(id<NSFetchedResultsControllerDelegate>)delegate inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [self requestAllWithPredicate:predicate sortedBy:sortTerm ascending:ascending inContext:context];
    
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:context
                                                                                                 sectionNameKeyPath:groupingKeyPath
                                                                                                          cacheName:nil];
    
    fetchedResultsController.delegate = delegate;
    
    NSError *error = nil;
    [fetchedResultsController performFetch:&error];
    
    if (error != nil)
    {
        abort(); // TODO: abort() ?
    }
    
    return fetchedResultsController;
}

#endif

#pragma mark - count

+ (NSUInteger)countOfEntitiesWithPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)localContext
{
    NSFetchRequest *fetchRequest = [self requestAllWithPredicate:predicate sortedBy:nil ascending:YES inContext:localContext];
    return [self countForFetchRequest:fetchRequest inContext:localContext];
}

+ (NSUInteger)countForFetchRequest:(NSFetchRequest *)fetchRequest inContext:(NSManagedObjectContext *)localContext
{
    NSError *error = nil;
    NSUInteger count = [localContext countForFetchRequest:fetchRequest error:&error];
    
    return count;
}

#pragma mark - aggregation

+ (id)aggregateOperation:(NSString *)function onAttribute:(NSString *)attributeName withPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context
{
    NSExpression *ex = [NSExpression expressionForFunction:function arguments:[NSArray arrayWithObject:[NSExpression expressionForKeyPath:attributeName]]];
    
    NSExpressionDescription *ed = [[NSExpressionDescription alloc] init];
    [ed setName:@"result"];
    [ed setExpression:ex];
    
    // determine the type of attribute, required to set the expression return type
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:context];
    NSAttributeDescription *attributeDescription = [[entityDescription attributesByName] objectForKey:attributeName];
    [ed setExpressionResultType:[attributeDescription attributeType]];
    NSArray *properties = [NSArray arrayWithObject:ed];
    
    NSFetchRequest *fetchRequest = [self requestAllWithPredicate:predicate sortedBy:nil ascending:YES inContext:context];
    [fetchRequest setPropertiesToFetch:properties];
    [fetchRequest setResultType:NSDictionaryResultType];
    
    //
    __block NSArray *results = nil;
    
    __typeof(context) __weak weakContext = context;
    [context performBlockAndWait:^{
        __typeof(weakContext) __strong strongContext = weakContext;
        if (strongContext == nil)
        {
            return;
        }
        
        NSError *error = nil;
        results = [strongContext executeFetchRequest:fetchRequest error:&error];
    }];
    
    //
    NSDictionary *resultsDictionary = [results firstObject];
    id resultValue = [resultsDictionary objectForKey:@"result"];
    
    //
    return resultValue;
}

#pragma mark - request

+ (NSFetchRequest *)requestAllWithPredicate:(NSPredicate *)predicate sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
    return [self requestAllWithPredicate:predicate sortedBy:sortTerm ascending:ascending fetchLimit:0 fetchOffset:0 fetchBatchSize:kAlecrimCoreDataDefaultFetchBatchSize inContext:context];
}

+ (NSFetchRequest *)requestAllWithPredicate:(NSPredicate *)predicate sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending fetchLimit:(NSUInteger)fetchLimit inContext:(NSManagedObjectContext *)context
{
    return [self requestAllWithPredicate:predicate sortedBy:sortTerm ascending:ascending fetchLimit:fetchLimit fetchOffset:0 fetchBatchSize:kAlecrimCoreDataDefaultFetchBatchSize inContext:context];
}

+ (NSFetchRequest *)requestAllWithPredicate:(NSPredicate *)predicate sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending fetchLimit:(NSUInteger)fetchLimit fetchOffset:(NSUInteger)fetchOffset fetchBatchSize:(NSUInteger)fetchBatchSize inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit:fetchLimit];
    [fetchRequest setFetchOffset:fetchOffset];
    
    if (fetchLimit == 1)
    {
        [fetchRequest setFetchBatchSize:0];
    }
    else
    {
        [fetchRequest setFetchBatchSize:fetchBatchSize];
    }
    
    if (sortTerm != nil)
    {
        NSArray *sortKeys = [sortTerm componentsSeparatedByString:@","];
        NSMutableArray *sortDescriptors = [NSMutableArray arrayWithCapacity:[sortKeys count]];
        
        [sortKeys enumerateObjectsUsingBlock:^(NSString *sortKey, NSUInteger idx, BOOL *stop) {
            
            NSString *customSortKey = sortKey;
            BOOL customAscending = ascending;

            NSArray *sortComponents = [sortKey componentsSeparatedByString:@":"];
            if (sortComponents.count > 1)
            {
                customSortKey = sortComponents[0];
                NSNumber *customAscendingNumber = [sortComponents lastObject];
                customAscending = [customAscendingNumber boolValue];
            }

            [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:customSortKey ascending:customAscending]];
            
        }];

        [fetchRequest setSortDescriptors:sortDescriptors];
    }
    
    return fetchRequest;
}

#pragma mark - public methods - delete

- (void)deleteInContext:(NSManagedObjectContext *)context
{
    if (![self isDeleted])
    {
        [context deleteObject:self];
    }
}

#pragma mark -

- (id)inContext:(NSManagedObjectContext *)otherContext
{
    //
    if (otherContext == [self managedObjectContext])
    {
        return self;
    }
    
    //
    if ([[self objectID] isTemporaryID])
    {
        NSError *error = nil;
        BOOL success = [[self managedObjectContext] obtainPermanentIDsForObjects:@[self] error:&error];
        if (!success)
        {
            return nil;
        }
    }

    //
    NSManagedObject *inContext = [otherContext objectRegisteredForID:[self objectID]]; // see if its already there
    if (inContext == nil)
    {
        NSError *error = nil;
        inContext = [otherContext existingObjectWithID:[self objectID] error:&error];
    }
    
    //
    return inContext;
}

- (void)copyAttributesFromManagedObject:(NSManagedObject *)sourceManagedObject
{
    NSDictionary *sourceAttributes = [[sourceManagedObject entity] attributesByName];
    
    @weakify(self);
    [[sourceAttributes allKeys] enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        
        @strongify(self);
        id value = [sourceManagedObject valueForKey:key];
        [self setValue:value forKey:key];
        
    }];
}

@end
