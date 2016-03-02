//
// Copyright (c) 2013, Taras Roshko
// All rights reserved.
//

// Significant modifications added by Yaroslav Vorontsov
// Copyright (c) 2015-2016, Yaroslav Vorontsov
// All rights reserved.

// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// The views and conclusions contained in the software and documentation are those
// of the authors and should not be interpreted as representing official policies,
// either expressed or implied, of the FreeBSD Project.
//

#import "TRAutocompleteView.h"
#import "TRAutocompleteItemsSource.h"
#import "TRAutocompletionCellFactory.h"
#import "TRAutocompleteViewConfig.h"


@interface TRAutocompleteView () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, readwrite) id <TRSuggestionItem> selectedSuggestion;
@property (nonatomic, readwrite) NSArray *suggestions;
@end

@implementation TRAutocompleteView
{
    __weak UITextField *_queryTextField;
    __weak UIViewController *_contextController;
    UITableView *_table;
    id <TRAutocompleteItemsSource> _itemsSource;
    id <TRAutocompletionCellFactory> _cellFactory;
    CGRect _kbFrame;
    NSTimer *_delayTimer;
}

#pragma mark - Initialization and deallocation

+ (instancetype)autocompleteViewBindTo:(UITextField *)textField
                           usingSource:(id <TRAutocompleteItemsSource>)itemsSource
                           cellFactory:(id <TRAutocompletionCellFactory>)factory
                          presentingIn:(UIViewController *)controller
{
    return [[self alloc] initWithFrame:CGRectZero
                             textField:textField
                           itemsSource:itemsSource
                           cellFactory:factory
                            controller:controller];
}

- (instancetype)initWithFrame:(CGRect)frame
                    textField:(UITextField *)textField
                  itemsSource:(id <TRAutocompleteItemsSource>)itemsSource
                  cellFactory:(id <TRAutocompletionCellFactory>)factory
                   controller:(UIViewController *)controller
{
    if ((self = [super initWithFrame:frame]))
    {
        [self loadDefaults];

        _queryTextField = textField;
        _itemsSource = itemsSource;
        _cellFactory = factory;
        _contextController = controller;
        _kbFrame = CGRectNull;

        _table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _table.backgroundColor = [UIColor clearColor];
        _table.layer.borderWidth = 0.5;
        _table.layer.borderColor = [[UIColor blackColor] CGColor];
        _table.separatorColor = self.separatorColor;
        _table.separatorStyle = self.separatorStyle;
        _table.delegate = self;
        _table.dataSource = self;
        // Hack to hide separators in empty table
        _table.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
        _table.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(queryChanged:)
                                                     name:UITextFieldTextDidChangeNotification
                                                   object:_queryTextField];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasShown:)
                                                     name:UIKeyboardDidShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidChange:)
                                                     name:UIKeyboardDidChangeFrameNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];

        [self addSubview:_table];
        self.userInteractionEnabled = YES;
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Configuration methods

- (void)loadDefaults
{
    self.backgroundColor = [UIColor whiteColor];
    self.separatorColor = [UIColor blackColor];
    self.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.topMargin = 0;
    self.bottomMargin = 0;
    self.cellHeight = 40;
}

#pragma mark - Frame calculation routines

- (CGRect)actualFrameFromKeyboardNotification:(NSNotification *)notification
{
    UIApplication *application = [UIApplication sharedApplication];
    NSDictionary *info = [notification userInfo];
    CGRect originalFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    return [_contextController.view convertRect:originalFrame fromView:application.keyWindow];
}

- (void)keyboardWasShown:(NSNotification *)notification
{
    _kbFrame = [self actualFrameFromKeyboardNotification:notification];
    [self updateLayout];
}

- (void)keyboardDidChange:(NSNotification *)notification
{
    TRLogDebug(@"KB Notification: %@", notification);
    CGRect frame = [self actualFrameFromKeyboardNotification:notification];
    if (!CGRectEqualToRect(frame, _kbFrame)) {
        _kbFrame = frame;
        [self updateLayout];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [self removeFromSuperview];
    _kbFrame = CGRectNull;
}

- (void)updateLayout
{
    CGFloat topKeyboardEdge = CGRectIsNull(_kbFrame) ? CGRectGetMaxY(_contextController.view.frame) : CGRectGetMinY(_kbFrame);
    // Detect top KB edge
    CGRect correctedTextFieldRect = [_contextController.view convertRect:_queryTextField.bounds fromView:_queryTextField];
    CGFloat calculatedY = correctedTextFieldRect.origin.y + correctedTextFieldRect.size.height + self.topMargin;
    CGFloat calculatedHeight = MIN(MAX(topKeyboardEdge - calculatedY - self.bottomMargin, 0.f), self.suggestions.count * self.cellHeight);
    self.frame = CGRectMake(CGRectGetMinX(correctedTextFieldRect), calculatedY, CGRectGetWidth(correctedTextFieldRect), calculatedHeight);
    _table.frame = self.bounds;
}

#pragma mark - Queries and result handling

- (void)queryChanged:(UITextField *)sender
{
    [self performQuery];
}

- (void)performQuery
{
    if ([_queryTextField.text length] >= _itemsSource.minimumCharactersToTrigger) {
        // FIXME: introduce Levenstein distance to calculate distance between 2 requests
        TRLogDebug(@"Invalidating search timer");
        [_delayTimer invalidate];
        _delayTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                       target:self
                                                     selector:@selector(timerDidFire:)
                                                     userInfo:@{ @"query": _queryTextField.text }
                                                      repeats:NO];
    } else {
        self.suggestions = nil;
        self.hidden = YES;
    }
}

- (void)timerDidFire:(NSTimer *)sender
{
    if (sender.isValid) {
        NSString *query = sender.userInfo[@"query"];
        TRLogDebug(@"Firing delayed search for query: %@", query);
        typeof(self) __weak that = self;
        [_itemsSource fetchItemsForQuery:query completionHandler:^(NSArray *suggestions, NSError *error) {
            [that handleResultsForQuery:query suggestions:suggestions error:error];
        }];
    }
}

- (void)handleResultsForQuery:(NSString *)query suggestions:(NSArray *)suggestions error:(NSError *)error
{
    if (error != nil) {
        // Failed with error
        TRLogDebug(@"Autocompletion failed with an error: %@ (%@)", error.localizedDescription, error);
        if (self.didFailWithError) {
            self.didFailWithError(error);
        }
    } else if (query.length < _itemsSource.minimumCharactersToTrigger) {
        // No triggering needed
        self.suggestions = nil;
        self.hidden = YES;
    } else if ([_queryTextField isFirstResponder]) {
        // We'll update the existing list only in case the query text field is the responder
        self.suggestions = suggestions;
        if (!self.suggestions.count && !self.hidden) {
            TRLogDebug(@"No suggestions received, hiding the view");
            self.hidden = YES;
        } else if (self.suggestions.count > 0) {
            if (!self.superview) {
                [_contextController.view addSubview:self];
            }
            self.hidden = NO;
            [self updateLayout];
            [_table reloadData];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.suggestions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"TRAutocompleteCell";
    UITableViewCell <TRAutocompletionCell> *cell = [tableView dequeueReusableCellWithIdentifier:identifier]
            ?: [_cellFactory createReusableCellWithIdentifier:identifier];
    NSAssert([cell isKindOfClass:[UITableViewCell class]], @"Cell must inherit from UITableViewCell");
    NSAssert([cell conformsToProtocol:@protocol(TRAutocompletionCell)], @"Cell must conform TRAutocompletionCell");
    id<TRSuggestionItem> suggestion = self.suggestions[(NSUInteger) indexPath.row];
    NSAssert([suggestion conformsToProtocol:@protocol(TRSuggestionItem)], @"Suggestion item must conform TRSuggestionItem");
    [cell updateWithSuggestionItem:suggestion];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id suggestion = self.suggestions[(NSUInteger) indexPath.row];
    NSAssert([suggestion conformsToProtocol:@protocol(TRSuggestionItem)], @"Suggestion item must conform TRSuggestionItem");
    self.selectedSuggestion = (id <TRSuggestionItem>) suggestion;
    _queryTextField.text = self.selectedSuggestion.completionText;
    [_queryTextField resignFirstResponder];
    if (self.didAutocompleteWith) {
        self.didAutocompleteWith(self.selectedSuggestion);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.cellHeight;
}

@end