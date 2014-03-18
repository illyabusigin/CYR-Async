//
//  CYR.h
//  CYR
//
//  Created by Illya Busigin on 3/12/14.
//  Copyright (c) 2014 Cyrillian, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CYRCallback)(NSError *error, void *context);
typedef void (^CYRTask)(CYRCallback callback, void *context);
typedef void (^CYRCompletion)(NSError *error, NSArray *results);
typedef BOOL (^CYRTest)(void);

/**
 Creates a new task to be used with the GCD async functions.
 @param The task block to submit to the GCD async functions. This parameter cannot be NULL.
 @return The newly created task.
 @discussion There are two input argument to a task: A `CYRCallback` object and context object. Upon completion of the task block the `callback` object @b must be called. The context object can be used to pass information between task blocks, among other things.
 */

CYRTask dispatch_task_create(CYRTask task);

/**
 Run an array of functions in series, each one running once the previous function has completed. If any functions in the series pass an error to its callback, no more functions are run and the completion block for the series is immediately called with the value of the error. Once the tasks have completed, the results are passed to the final completion block as an array.
 @param tasks An array of `CYRTask` objects to be executed. Each function is passed a callback(error, context) it must call on completion with an error (which can be `nil`) and an optional context value. If any of the objects in the array are not `CYRTask` objects an exception will be thrown.
 @param completion A block object called when all tasks are completed or an error occurs. The block returns an error object which may be `nil` if no errors occurred and a results array which contains the context object for each task.
 */
void dispatch_series(NSArray *tasks, CYRCompletion completion);

/**
 Run an array of functions in parallel, without waiting until the previous function has completed. If any of the functions pass an error to its callback, the completion block is immediately called with the value of the error. Once the tasks have completed, the results are passed to the completion block as an array.
 @param tasks An array of `CYRTask` objects to be executed. Each function is passed a callback(error, context) it must call on completion with an error (which can be `nil`) and an optional context value. If any of the objects in the array are not `CYRTask` objects an exception will be thrown.
 @param completion A block object called when all tasks are completed or an error occurs. The block returns an error object which may be `nil` if no errors occurred and a results array which contains the context object for each task.
 */
void dispatch_parallel(NSArray *tasks, CYRCompletion completion);

/**
 Run an array of functions in parallel, with a maxmimum limit of tasks that can be executing at any time. If any of the functions pass an error to its callback, the completion block is immediately called with the value of the error. Once the tasks have completed, the results are passed to the completion block as an array.
 @param tasks An array of `CYRTask` objects to be executed. Each function is passed a callback(error, context) it must call on completion with an error (which can be `nil`) and an optional context value. If any of the objects in the array are not `CYRTask` objects an exception will be thrown.
 @param limit The maximum number of tasks to execute at any time.
 @param completion A block object called when all tasks are completed or an error occurs. The block returns an error object which may be `nil` if no errors occurred and a results array which contains the context object for each task.
 @note The tasks are not executed in batches, so there is no guarantee that the first "limit" tasks will complete before any others are started.
 */
void dispatch_parallel_limit(NSArray *tasks, NSUInteger limit, CYRCompletion completion);

/**
 Repeatedly calls the task, while test block returns `YES`. Calls the completion block when stopped, or an error occurs.
 @param test Synchronous truth test to perform before each execution of the task.
 @param task A task to call each time the test passes. The task is passed a callback(error, context) it must call on completion with an error (which can be `nil`) and an optional context parameter.
 @param completion A block which is called after the test fails and/or when repeated execution of the task has stopped.
 */
void dispatch_whilst(CYRTest test, CYRTask task, CYRCompletion completion);

/**
 Repeatedly calls the task while test block returns `YES` with a maximum `limit` the task can be executed. Calls the completion block when stopped, or an error occurs.
 @param test Synchronous truth test to perform before each execution of the task.
 @param task A task to call each time the test passes. The task is passed a callback(error, context) it must call on completion with an error (which can be `nil`) and an optional context parameter.
 @param limit The maximum number of times the task can be executed.
 @param completion A block which is called after the test fails and/or when repeated execution of the task has stopped.
 */
void dispatch_whilst_limit(CYRTest test, CYRTask task, NSUInteger limit, CYRCompletion completion);

/**
 The post check version of `dispatch_whilst`. To reflect the difference in the order of operations test and task arguments are switched. Repeatedly calls the task while test block returns `YES`. Calls the completion block when stopped, or an error occurs.
 @param test Synchronous truth test to perform before each execution of the task.
 @param task A task to call each time the test passes. The task is passed a callback(error, context) it must call on completion with an error (which can be `nil`) and an optional context parameter.
 @param completion A block which is called after the test fails and/or when repeated execution of the task has stopped.
 */
void dispatch_do_whilst(CYRTask task, CYRTest test, CYRCompletion completion);

/**
 The post check version of `dispatch_whilst`. To reflect the difference in the order of operations test and task arguments are switched. Repeatedly calls the task while test block returns `YES` with a maximum `limit` the task can be called. Calls the completion block when stopped, or an error occurs.
 @param test Synchronous truth test to perform before each execution of the task.
 @param task A task to call each time the test passes. The task is passed a callback(error, context) it must call on completion with an error (which can be `nil`) and an optional context parameter.
 @param limit The maximum number of times the task can be executed.
 @param completion A block which is called after the test fails and/or when repeated execution of the task has stopped.
 */
void dispatch_do_whilst_limit(CYRTask task, CYRTest test, NSUInteger limit, CYRCompletion completion);

/**
 Repeatedly call the task, until the test block returns `YES`. Calls the completion block when stopped, or an error occurs.
 @param test Synchronous truth test to perform before each execution of the task.
 @param task A task to call each time the test passes. The task is passed a callback(error, context) it must call on completion with an error (which can be `nil`) and an optional context parameter.
 @param limit The maximum number of times the task can be executed.
 @param completion A block which is called after the test fails and/or when repeated execution of the task has stopped.
 @discussion The inverse of dispatch_whilst.
*/
void dispatch_until(CYRTest test, CYRTask task, CYRCompletion completion);

/**
 Repeatedly call the task, until the test block returns `YES` or the `limit` is reached. Calls the completion block when stopped, or an error occurs.
 @param test Synchronous truth test to perform before each execution of the task.
 @param task A task to call each time the test passes. The task is passed a callback(error, context) it must call on completion with an error (which can be `nil`) and an optional context parameter.
 @param limit The maximum number of times the task can be executed.
 @param completion A block which is called after the test fails and/or when repeated execution of the task has stopped.
 @discussion The inverse of dispatch_whilst_limit.
 */
void dispatch_until_limit(CYRTest test, CYRTask task, NSUInteger limit, CYRCompletion completion);

/**
 Repeatedly call the task, until the test block returns `YES`. To reflect the difference in the order of operations test and task arguments are switched. Calls the completion block when stopped, or an error occurs.
 @param test Synchronous truth test to perform before each execution of the task.
 @param task A task to call each time the test passes. The task is passed a callback(error, context) it must call on completion with an error (which can be `nil`) and an optional context parameter.
 @param completion A block which is called after the test fails and/or when repeated execution of the task has stopped.
 @discussion Like dispatch_do_whilst except the test is inverted.
 */
void dispatch_do_until(CYRTask task, CYRTest test, CYRCompletion completion);

/**
 Repeatedly call the task, until the test block returns `YES` or the `limit` is reached. To reflect the difference in the order of operations test and task arguments are switched. Calls the completion block when stopped, or an error occurs.
 @param test Synchronous truth test to perform before each execution of the task.
 @param task A task to call each time the test passes. The task is passed a callback(error, context) it must call on completion with an error (which can be `nil`) and an optional context parameter.
 @param limit The maximum number of times the task can be executed.
 @param completion A block which is called after the test fails and/or when repeated execution of the task has stopped.
 @discussion Like dispatch_do_whilst_limit except the test is inverted.
 */
void dispatch_do_until_limit(CYRTask task, CYRTest test, NSUInteger limit, CYRCompletion completion);

/**
 Calls the asynchronous task repeatedly, in series, indefinitely. If an error is passed to tasks callback then the completion block is called with the error, otherwise it will never be called.
 @param task The task to execute. The task is passed a callback(error, context) it must call on completion with an error (which can be `nil`) and an optional context parameter.
 @param completion A block which is called when repeated execution of the task has stopped due to an error.
 */
void dispatch_forever(CYRTask task, CYRCompletion completion);

/**
 Calls the asynchronous task repeatedly, in series, for the specified interval, indefinitely. If an error is passed to tasks callback then the completion block is called with the error, otherwise it will never be called.
 @param task The task to execute. The task is passed a callback(error, context) it must call on completion with an error (which can be `nil`) and an optional context parameter.
 @param interval The time interval, in seconds. Must be a positive value.
 @param completion A block which is called when repeated execution of the task has stopped due to an error.
 */
void dispatch_interval(CYRTask task, NSTimeInterval interval, CYRCompletion completion);

/**
 Calls the asynchronous task repeatedly, in series, for the specified interval, indefinitely. If an error is passed to tasks callback then the completion block is called with the error, otherwise it will never be called.
 @param task The task to execute. The task is passed a callback(error, context) it must call on completion with an error (which can be `nil`) and an optional context parameter.
 @param interval The time interval, in seconds. Must be a positive value.
 @param limit The maximum number of times the task should be executed.
 @param completion A block which is called when repeated execution of the task has stopped due to an error.
 */
void dispatch_interval_limit(CYRTask task, NSTimeInterval interval, NSUInteger limit, CYRCompletion completion);