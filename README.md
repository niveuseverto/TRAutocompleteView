What is TRAutocompleteView?
---------------------
<p align="center">
  <img src="/screenshots/iphone_portrait.png" />
</p>

<p align="center">
  <img src="/screenshots/ipad.png" />
</p>

TRAutocompleteView is highly customizable autocomplete/suggestionslist view. 
No inheritance, just a single line of code - attach TRAutocompleteView to any existing instance of UITextField, implement your custom data source and cell factory, customize look and feel and that's it! 
It works on the iPhone and iPad and supports all possible orientations.


Step 0: Prerequisites
---------------------
You'll need an iOS 8.0+ project

Step 1: Get TRAutocompleteView
------------------------------
Via CocoaPods:

````bash
pod "TRAutocompleteView", "~>1.2", :git => "https://github.com/ashaman/TRAutocompleteView.git"
````

Via Carthage:

````bash
github "ashaman/TRAutocompleteView" ~>1.2
````

Step 2: Use it
--------------

Assume you have two instance variables in your view controller

````objective-c
    IBOutlet UITextField *_textField;
    TRAutocompleteView *_autocompleteView;
````

Bind autocomplete view to that UITextField (e.g in loadView method):

````objective-c
_autocompleteView = [TRAutocompleteView autocompleteViewBindedTo:_textField
                                                     usingSource:YOUR_SOURCE_HERE
                                                     cellFactory:YOUR_FACTORY_HERE
                                                    presentingIn:self];
````

What's going on here?
You've just binded _autocompleteView to _textField, and used your custom completion source with custom cell factory. Positioning, resizing, etc will be handled for you automatically.
You should implement the following protocols:
````objective-c

@protocol TRAutocompleteItemsSource <NSObject>
- (NSUInteger)minimumCharactersToTrigger;
- (void)fetchItemsForQuery:(NSString *)query completionHandler:(void (^)(NSArray *, NSError *))suggestionsReady;
@end

@protocol TRSuggestionItem <NSObject>
- (NSString *)completionText;
@end

@protocol TRAutocompletionCell <NSObject>
- (void)updateWithSuggestionItem:(id <TRSuggestionItem>)item;
@end

@protocol TRAutocompletionCellFactory <NSObject>
- (UITableViewCell <TRAutocompletionCell> *)createReusableCellWithIdentifier:(NSString *)identifier;
@end

````

Conform TRAutocompleteItemsSource to provide your own items source, conform TRAutocompletionCellFactory to provide your custom cells.

Step 3: Customize TRAutocompleteView
------------------------------------
  
**TRAutocompleteView Customizations**

Main customization step is to create your own cell and use it with CellFactory, but also you can use following properties

````objective-c
@property (nonatomic, strong) UIColor *separatorColor;
@property (nonatomic, assign) UITableViewCellSeparatorStyle separatorStyle;

@property (nonatomic, assign) CGFloat topMargin;
@property (nonatomic, assign) CGFloat bottomMargin;
@property (nonatomic, assign) CGFloat cellHeight;
````

Also, properties for tracking completion state:

````objective-c
@property (nonatomic, readonly) id <TRSuggestionItem> selectedSuggestion;
@property (nonatomic, readonly) NSArray *suggestions;
@property (nonatomic, copy) void (^didAutocompleteWith)(id <TRSuggestionItem>);
@property (nonatomic, copy) void (^didFailWithError)(NSError *);
````

And some methods to perform queries or update layout in case of rotation:
````objective-c
- (void)updateLayout;
- (void)performQuery;
````

License
------------------------
FreeBSD