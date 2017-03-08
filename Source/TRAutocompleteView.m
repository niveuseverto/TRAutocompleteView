//
// Copyright (c) 2013, Taras Roshko
// All rights reserved.
//

// Significant modifications added by Yaroslav Vorontsov
// Copyright (c) 2015-2017, Yaroslav Vorontsov
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
#import "TRAutocompleteItemSource.h"
#import "TRAutocompleteCellConfiguration.h"
#import "TRAutocompleteViewConfiguration.h"

@interface TRAutocompleteView () <UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic, readonly) id<TRAutocompleteItemSource> itemSource;
@property (strong, nonatomic, readonly) id<TRAutocompleteCellConfiguration> cellConfiguration;
@property (strong, nonatomic, readwrite) id<TRSuggestionItem> selectedSuggestion;
@property (strong, nonatomic, readwrite) NSArray *suggestions;
@property (assign, nonatomic, readonly) CGFloat cellHeight;
@property (copy, nonatomic, readonly) NSString *cellReuseIdentifier;
@property (weak, nonatomic, readonly) UITextField *queryTextField;
@property (weak, nonatomic, readonly) UIViewController *contextController;
@end

@implementation TRAutocompleteView
{
    UITableView *_tableView;
    CGRect _kbFrame;
}

#pragma mark - Initialization and deallocation

+ (instancetype)viewBoundTo:(UITextField *)textField
                usingSource:(id <TRAutocompleteItemSource>)itemsSource
          cellConfiguration:(id <TRAutocompleteCellConfiguration>)factory
               presentingIn:(UIViewController *)controller
{
    return [[self alloc] initWithFrame:CGRectZero
                             textField:textField
                            itemSource:itemsSource
                     cellConfiguration:factory
                            controller:controller];
}

- (instancetype)initWithFrame:(CGRect)frame
                    textField:(UITextField *)textField
                   itemSource:(id <TRAutocompleteItemSource>)itemSource
            cellConfiguration:(id <TRAutocompleteCellConfiguration>)configuration
                   controller:(UIViewController *)controller
{
    if ((self = [super initWithFrame:frame])) {
        NSParameterAssert(textField != nil);
        NSParameterAssert(itemSource != nil);
        NSParameterAssert(configuration != nil);
        NSParameterAssert(controller != nil);

        // External parameters
        _cellHeight = configuration.cellHeight;
        _cellReuseIdentifier = NSStringFromClass(configuration.cellClass);
        _queryTextField = textField;
        _itemSource = itemSource;
        _cellConfiguration = configuration;
        _contextController = controller;
        _kbFrame = CGRectNull;

        // Defaults
        self.backgroundColor = [UIColor whiteColor];
        self.layoutMargins = UIEdgeInsetsZero;
        self.preservesSuperviewLayoutMargins = NO;
        self.endEditingOnCompletion = YES;
        self.userInteractionEnabled = YES;

        // Notifications
        [self.notificationCenter addObserver:self
                                     selector:@selector(queryChanged:)
                                         name:UITextFieldTextDidChangeNotification
                                       object:self.queryTextField];
        [self.notificationCenter addObserver:self
                                    selector:@selector(editingFinished:)
                                        name:UITextFieldTextDidEndEditingNotification
                                      object:self.queryTextField];
        [self.notificationCenter addObserver:self
                                    selector:@selector(keyboardWasShown:)
                                        name:UIKeyboardDidShowNotification
                                      object:nil];
        [self.notificationCenter addObserver:self
                                    selector:@selector(keyboardDidChange:)
                                        name:UIKeyboardDidChangeFrameNotification
                                      object:nil];
        [self.notificationCenter addObserver:self
                                    selector:@selector(keyboardWillHide:)
                                        name:UIKeyboardWillHideNotification
                                      object:nil];

        // Table view
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        [self addSubview:self.tableView];
    }
    return self;
}

- (void)dealloc
{
    [self.notificationCenter removeObserver:self];
}

#pragma mark - Getters and setters

- (NSNotificationCenter *)notificationCenter
{
    return [NSNotificationCenter defaultCenter];
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        // Hack to hide separators in empty table
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        // Register cell
        if ([self.cellConfiguration respondsToSelector:@selector(cellNib)]) {
            [_tableView registerNib:self.cellConfiguration.cellNib forCellReuseIdentifier:self.cellReuseIdentifier];
        } else {
            [_tableView registerClass:self.cellConfiguration.cellClass forCellReuseIdentifier:self.cellReuseIdentifier];
        }
    }
    return _tableView;
}

#pragma mark - Frame calculation routines

- (CGRect)actualFrameFromKeyboardNotification:(NSNotification *)notification
{
    UIApplication *application = [UIApplication sharedApplication];
    NSDictionary *info = [notification userInfo];
    CGRect originalFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    return [self.contextController.view convertRect:originalFrame fromView:application.keyWindow];
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
    // Detect top KB edge
    CGFloat topKeyboardEdge = CGRectIsNull(_kbFrame) ? CGRectGetMaxY(self.contextController.view.frame) : CGRectGetMinY(_kbFrame);
    CGRect textFieldRect = [self.contextController.view convertRect:self.queryTextField.bounds fromView:self.queryTextField];
    // Get top coordinate for the view
    CGFloat x = CGRectGetMinX(textFieldRect) + self.layoutMargins.left;
    CGFloat y = CGRectGetMaxY(textFieldRect) + self.layoutMargins.top;
    // Width is corrected using margins
    CGFloat width = MAX(CGRectGetWidth(textFieldRect) - self.layoutMargins.left - self.layoutMargins.right, 0);
    // Height is calculated based on 'extendToKeyboard' flag and available space/content space
    CGFloat availableHeight = MAX(topKeyboardEdge - y - self.layoutMargins.bottom, 0.f);
    CGFloat height = self.extendToKeyboardEdge ? availableHeight : MIN(availableHeight, self.suggestions.count * self.cellHeight);
    self.frame = CGRectMake(x, y, width, height);
    self.tableView.frame = self.bounds;
}

#pragma mark - Action handlers

- (void)queryChanged:(NSNotification *)note
{
    NSString *query = [note.object text];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(performQuery:) withObject:query afterDelay:0.3f];
}

- (void)editingFinished:(UITextField *)sender
{
    if (self.hideOnFocusLoss) {
        [self removeFromSuperview];
        _kbFrame = CGRectNull;
    }
}

#pragma mark - Queries and result handling

- (void)performQuery:(NSString *)query
{
    // Check again due to delayed -performSelector invocation
    if ([query isEqualToString:self.queryTextField.text]
            && query.length >= self.itemSource.minimumCharactersToTrigger) {
        // FIXME: introduce Levenstein distance to calculate distance between 2 requests
        typeof(self) __weak that = self;
        [self.itemSource fetchItemsForQuery:query completionHandler:^(NSArray *suggestions, NSError *error) {
            [that handleResultsForQuery:query suggestions:suggestions error:error];
        }];
    } else {
        self.suggestions = nil;
        self.hidden = YES;
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
    } else if (query.length < self.itemSource.minimumCharactersToTrigger) {
        // No triggering needed
        self.suggestions = nil;
        self.hidden = YES;
    } else if (self.queryTextField.isFirstResponder) {
        // We'll update the existing list only in case the query text field is the responder
        self.suggestions = suggestions;
        if (!self.suggestions.count && !self.hidden) {
            TRLogDebug(@"No suggestions received, hiding the view");
            self.hidden = YES;
        } else if (self.suggestions.count > 0) {
            if (!self.superview) {
                [self.contextController.view addSubview:self];
            }
            self.hidden = NO;
            [self updateLayout];
            [self.tableView reloadData];
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
    UITableViewCell<TRAutocompleteCell> *cell = [tableView dequeueReusableCellWithIdentifier:self.cellReuseIdentifier
                                                                                forIndexPath:indexPath];
    id<TRSuggestionItem> suggestion = self.suggestions[(NSUInteger) indexPath.row];
    NSAssert([cell isKindOfClass:[UITableViewCell class]], @"Cell must inherit from UITableViewCell");
    NSAssert([cell conformsToProtocol:@protocol(TRAutocompleteCell)], @"Cell must conform TRAutocompleteCell");
    NSAssert([suggestion conformsToProtocol:@protocol(TRSuggestionItem)], @"Suggestion item must conform TRSuggestionItem");
    [cell updateWithSuggestionItem:suggestion];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<TRSuggestionItem> suggestion = self.suggestions[(NSUInteger) indexPath.row];
    NSAssert([suggestion conformsToProtocol:@protocol(TRSuggestionItem)], @"Suggestion item must conform TRSuggestionItem");
    self.selectedSuggestion = suggestion;
    if (self.didAutocompleteWith) {
        self.didAutocompleteWith(suggestion);
    }
    if (self.endEditingOnCompletion) {
        [self.queryTextField resignFirstResponder];
        self.queryTextField.text = suggestion.completionText;
    }
    self.hidden = YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.cellHeight;
}

@end
