//
//  CYRAsyncTests.m
//  CYRAsyncTests
//
//  Created by Illya Busigin on 3/14/14.
//  Copyright (c) 2014 Cyrillian, Inc. All rights reserved.
//

#import <Kiwi/Kiwi.h>

#import "CYR+Async.h"

SPEC_BEGIN(CYRDispatchSeriesSpec)

describe(@"The CYR async utilities", ^{
    
    context(@"while using dispatch_series", ^{
        
        context(@"when executing valid tasks", ^{
            __block NSError *theError = nil;
            __block NSArray *theResults = nil;
            __block BOOL completionBlockCalled = NO;
            
            beforeAll(^{
                CYRTask task1 = dispatch_task_create(^(CYRCallback callback, void *context) {
                    return callback(nil, @"one");
                });
                
                CYRTask task2 = dispatch_task_create(^(CYRCallback callback, void *context) {
                    return callback(nil, @"two");
                });
                
                dispatch_series(@[task1, task2], ^(NSError *error, NSArray *results) {
                    theError = error;
                    theResults = results;
                    completionBlockCalled = YES;
                });
            });
            
            it(@"should return a nil error object", ^{
                [[expectFutureValue(theError) shouldEventually] beNil];
            });
            
            it(@"should return a valid results array", ^{
                [[expectFutureValue(theResults) shouldEventually] beNonNil];
            });
            
            it(@"should return 2 context items in the results array", ^{
                [[expectFutureValue(theValue(theResults.count)) shouldEventually] equal:theValue(2)];
            });
            
            it(@"should have executed the tasks in a serial fashion", ^{
                [[expectFutureValue(theResults) shouldEventually] equal:@[@"one", @"two"]];
            });
            
            it(@"should call the completion block", ^{
                [[expectFutureValue(theValue(completionBlockCalled)) shouldEventually] equal:theValue(YES)];
            });
        });
        
        context(@"when executing a task list that has an error", ^{
            
            __block NSError *theError = nil;
            __block NSArray *theResults = nil;
            __block BOOL completionBlockCalled = NO;
            
            beforeAll(^{
                CYRTask task1 = dispatch_task_create(^(CYRCallback callback, void *context) {
                    return callback(nil, @"one");
                });
                
                CYRTask task2 = dispatch_task_create(^(CYRCallback callback, void *context) {
                    NSError *error = [NSError errorWithDomain:@"kTestDomain" code:1 userInfo:@{}];
                    return callback(error, @"two");
                });
                
                CYRTask task3 = dispatch_task_create(^(CYRCallback callback, void *context) {
                    return callback(nil, @"three");
                });
                
                dispatch_series(@[task1, task2, task3], ^(NSError *error, NSArray *results) {
                    theError = error;
                    theResults = results;
                    completionBlockCalled = YES;
                });
            });
            
            it(@"should call the completion block", ^{
                [[expectFutureValue(theValue(completionBlockCalled)) shouldEventually] equal:theValue(YES)];
            });
            
            it(@"should return a valid error object", ^{
                [[expectFutureValue(theError) shouldEventually] beNonNil];
            });
            
            it(@"should have only two results instead of three, due to the error", ^{
                [[expectFutureValue(theValue(theResults.count)) shouldEventually] equal:theValue(2)];
            });
            
            it(@"should return a partial results list since the second task had an error", ^{
                [[expectFutureValue(theResults) shouldEventually] equal:@[@"one", @"two"]];
            });
        });
        
        context(@"when passing nil contexts for all tasks", ^{
            
            __block NSError *theError = nil;
            __block NSArray *theResults = nil;
            __block BOOL completionBlockCalled = NO;
            
            beforeAll(^{
                CYRTask task1 = dispatch_task_create(^(CYRCallback callback, void *context) {
                    return callback(nil, nil);
                });
                
                CYRTask task2 = dispatch_task_create(^(CYRCallback callback, void *context) {
                    return callback(nil, nil);
                });
                
                CYRTask task3 = dispatch_task_create(^(CYRCallback callback, void *context) {
                    return callback(nil, nil);
                });
                
                dispatch_series(@[task1, task2, task3], ^(NSError *error, NSArray *results) {
                    theError = error;
                    theResults = results;
                    completionBlockCalled = YES;
                });
            });
            
            it(@"should return a valid results object", ^{
                [[expectFutureValue(theResults) shouldEventually] beNonNil];
            });
            
            it(@"should have zero since nil was passed back in all callback contexts", ^{
                [[expectFutureValue(theValue(theResults.count)) shouldEventually] equal:theValue(0)];
            });
        });
    });
});

SPEC_END
