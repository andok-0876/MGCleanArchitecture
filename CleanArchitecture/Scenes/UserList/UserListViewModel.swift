//
// UserListViewModel.swift
// CleanArchitecture
//
// Created by Tuan Truong on 1/14/19.
// Copyright © 2019 Framgia. All rights reserved.
//

struct UserListViewModel {
    let navigator: UserListNavigatorType
    let useCase: UserListUseCaseType
}

// MARK: - ViewModelType
extension UserListViewModel: ViewModelType {
    struct Input {
        let loadTrigger: Driver<Void>
        let reloadTrigger: Driver<Void>
        let loadMoreTrigger: Driver<Void>
        let selectUserTrigger: Driver<IndexPath>
    }
    
    struct Output {
        let error: Driver<Error>
        let loading: Driver<Bool>
        let refreshing: Driver<Bool>
        let loadingMore: Driver<Bool>
        let fetchItems: Driver<Void>
        let userList: Driver<[User]>
        let selectedUser: Driver<Void>
        let isEmptyData: Driver<Bool>
    }
    
    func transform(_ input: Input) -> Output {
        let loadMoreOutput = setupLoadMorePaging(
            loadTrigger: input.loadTrigger,
            getItems: useCase.getUserList,
            refreshTrigger: input.reloadTrigger,
            refreshItems: useCase.getUserList,
            loadMoreTrigger: input.loadMoreTrigger,
            loadMoreItems: useCase.loadMoreUserList)
        
        let (page, fetchItems, loadError, loading, refreshing, loadingMore) = loadMoreOutput
        
        let userList = page
            .map { $0.items.map { $0 } }
            .asDriverOnErrorJustComplete()
        
        let selectedUser = input.selectUserTrigger
            .withLatestFrom(userList) {
                return ($0, $1)
            }
            .map { indexPath, userList in
                return userList[indexPath.row]
            }
            .do(onNext: { user in
                self.navigator.toUserDetail(user: user)
            })
            .mapToVoid()
        
        let isEmptyData = checkIfDataIsEmpty(fetchItemsTrigger: fetchItems,
                                             loadTrigger: Driver.merge(loading, refreshing),
                                             items: userList)
        
        return Output(
            error: loadError,
            loading: loading,
            refreshing: refreshing,
            loadingMore: loadingMore,
            fetchItems: fetchItems,
            userList: userList,
            selectedUser: selectedUser,
            isEmptyData: isEmptyData
        )
    }
}
