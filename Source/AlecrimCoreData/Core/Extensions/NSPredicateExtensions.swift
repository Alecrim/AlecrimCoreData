//
//  NSPredicateExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-06-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

//
//  Portions of this Software may utilize modified versions of the following
//  open source copyrighted material, the use of which is hereby acknowledged:
//
//  QueryKit [https://github.com/QueryKit/QueryKit]
//  Copyright (c) 2012-2014 Kyle Fuller. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//     list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import Foundation

public func && (left: NSPredicate, right: NSPredicate) -> NSPredicate {
    return NSCompoundPredicate(type: .and, subpredicates: [left, right])
}

public func || (left: NSPredicate, right: NSPredicate) -> NSPredicate {
    return NSCompoundPredicate(type: .or, subpredicates: [left, right])
}

prefix public func ! (left: NSPredicate) -> NSPredicate {
    return NSCompoundPredicate(type: .not, subpredicates: [left])
}
