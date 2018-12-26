//
//  MIMainViewController.m
//  MetalImage
//
//  Created by Sylar on 2018/12/25.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIMainViewController.h"

@interface MIMainViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *titles;
@end

@implementation MIMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [[UIView alloc] init];
    [self.view addSubview:_tableView];
    
    _titles = @[@"Camera",
                @"Video",
                @"TwoInput"
                ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.alpha = 1.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ID = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    
    cell.textLabel.text = self.titles[indexPath.row];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.titles.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger row = indexPath.row;
    UIViewController *vc;
    switch (row) {
        case 0:
            vc = [[NSClassFromString(@"MICameraViewController") alloc] init];
            break;
        case 1:
            vc = [[NSClassFromString(@"MIVideoViewController") alloc] init];
            break;
        case 2:
            vc = [[NSClassFromString(@"MIVideoTwoInputViewController") alloc] init];
            break;
        default:
            break;
    }
    [self.navigationController pushViewController:vc animated:YES];
}


@end
