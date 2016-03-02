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

@import UIKit;

@protocol TRAutocompleteItemsSource;
@protocol TRAutocompletionCellFactory;
@protocol TRSuggestionItem;

@interface TRAutocompleteView : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, readonly) id <TRSuggestionItem> selectedSuggestion;
@property (nonatomic, readonly) NSArray *suggestions;
@property (nonatomic, copy) void (^didAutocompleteWith)(id <TRSuggestionItem>);
@property (nonatomic, copy) void (^didFailWithError)(NSError *);
@property (nonatomic, strong) UIColor *separatorColor;
@property (nonatomic, assign) UITableViewCellSeparatorStyle separatorStyle;
@property (nonatomic, assign) CGFloat topMargin;
@property (nonatomic, assign) CGFloat bottomMargin;
@property (nonatomic, assign) CGFloat cellHeight;
+ (instancetype)autocompleteViewBindTo:(UITextField *)textField
                           usingSource:(id <TRAutocompleteItemsSource>)itemsSource
                           cellFactory:(id <TRAutocompletionCellFactory>)factory
                          presentingIn:(UIViewController *)controller;
- (void)updateLayout;
- (void)performQuery;
@end