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

#import <UIKit/UIKit.h>

@protocol TRAutocompleteItemSource;
@protocol TRAutocompleteCellConfiguration;
@protocol TRSuggestionItem;


typedef NS_OPTIONS(NSUInteger, TRAutocompleteOptions) {
    TRAutocompleteListNarrowingMode = 1 << 0,
    TRAutocompleteEndEditingOnCompletion = 1 << 1,
    TRAutocompleteExtendToKeyboardEdge = 1 << 2,
    TRAutocompleteHideOnFocusLoss = 1 << 3,
    TRAutocompleteListDefault = TRAutocompleteEndEditingOnCompletion
};


@interface TRAutocompleteView : UIView <UIGestureRecognizerDelegate>
@property (strong, nonatomic, readonly) UITableView *tableView;
@property (strong, nonatomic, readonly) id <TRSuggestionItem> selectedSuggestion;
@property (strong, nonatomic, readonly) NSArray *suggestions;
@property (assign, nonatomic) TRAutocompleteOptions options;
@property (copy, nonatomic) void (^didAutocompleteWith)(id <TRSuggestionItem>);
@property (copy, nonatomic) void (^didFailWithError)(NSError *);
@property (weak, nonatomic) UIView *anchorView; // can be specified as the 1st top view over autocomplete view
+ (instancetype)viewBoundTo:(UITextField *)textField
                usingSource:(id <TRAutocompleteItemSource>)itemsSource
          cellConfiguration:(id <TRAutocompleteCellConfiguration>)factory
               presentingIn:(UIViewController *)controller;
- (void)updateLayout;
@end
