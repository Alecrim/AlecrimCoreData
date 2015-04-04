//
//  AlecrimCoreData.h
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-24.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    #import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
    #import <Cocoa/Cocoa.h>
#endif

//! Project version number for AlecrimCoreData.
FOUNDATION_EXPORT double AlecrimCoreDataVersionNumber;

//! Project version string for AlecrimCoreData.
FOUNDATION_EXPORT const unsigned char AlecrimCoreDataVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <AlecrimCoreData/PublicHeader.h>


