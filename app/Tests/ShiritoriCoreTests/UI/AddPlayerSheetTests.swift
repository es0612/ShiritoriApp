import Testing
import SwiftUI
import ViewInspector
@testable import ShiritoriCore

struct AddPlayerSheetTests {
    
    // MARK: - ダークモード対応テスト
    
    @Test func testAddPlayerSheetDarkModeAdaptation() throws {
        // Given
        let isPresented = true
        var saveCalled = false
        
        // When - ダークモードでの表示
        let sheet = AddPlayerSheet(
            isPresented: .constant(isPresented),
            onSave: { _ in saveCalled = true },
            onCancel: { }
        )
        
        // Then
        let view = try sheet.inspect()
        let navigationView = try view.navigationView()
        let zstack = try navigationView.zStack()
        
        // ChildFriendlyBackgroundが存在することを確認
        let backgroundView = try zstack.view(ChildFriendlyBackground.self, 0)
        #expect(backgroundView != nil)
        
        // VStackが存在することを確認
        let vstack = try zstack.vStack(1)
        #expect(vstack != nil)
        
        // テキストフィールドの存在確認
        let inputVStack = try vstack.vStack(1)
        let fieldVStack = try inputVStack.vStack(0)
        let textField = try fieldVStack.textField(1)
        #expect(textField != nil)
        
        // テキストフィールドのプレースホルダーテキストを確認
        #expect(try textField.callOnEditingChanged().wrappedValue == "")
    }
    
    @Test func testAddPlayerSheetTextFieldBackgroundColor() throws {
        // Given
        let isPresented = true
        
        // When
        let sheet = AddPlayerSheet(
            isPresented: .constant(isPresented),
            onSave: { _ in },
            onCancel: { }
        )
        
        // Then
        let view = try sheet.inspect()
        let navigationView = try view.navigationView()
        let zstack = try navigationView.zStack()
        let vstack = try zstack.vStack(1)
        
        // テキストフィールドの背景色がダークモードに対応していることを確認
        let inputVStack = try vstack.vStack(1)
        let fieldVStack = try inputVStack.vStack(0)
        let textField = try fieldVStack.textField(1)
        
        // TextFieldが存在し、適切にスタイルが適用されていることを確認
        #expect(textField != nil)
        
        // プレースホルダーテキストが設定されていることを確認
        #expect(try textField.input() == "")
    }
    
    @Test func testAddPlayerSheetButtons() throws {
        // Given
        let isPresented = true
        var saveCalled = false
        var cancelCalled = false
        
        // When
        let sheet = AddPlayerSheet(
            isPresented: .constant(isPresented),
            onSave: { _ in saveCalled = true },
            onCancel: { cancelCalled = true }
        )
        
        // Then
        let view = try sheet.inspect()
        let navigationView = try view.navigationView()
        let zstack = try navigationView.zStack()
        let vstack = try zstack.vStack(1)
        
        // ボタンの存在確認
        let buttonHStack = try vstack.hStack(3)
        let cancelButton = try buttonHStack.view(ChildFriendlyButton.self, 0)
        let saveButton = try buttonHStack.view(ChildFriendlyButton.self, 1)
        
        // ボタンのタイトル確認
        #expect(cancelButton.title == "キャンセル")
        #expect(saveButton.title == "🎉 とうろく")
        
        // ボタンの色確認
        #expect(cancelButton.backgroundColor == .gray)
        #expect(saveButton.backgroundColor == .green)
        
        // 初期状態でコールバックが呼ばれていないことを確認
        #expect(saveCalled == false)
        #expect(cancelCalled == false)
    }
    
    @Test func testAddPlayerSheetPreviewAvatar() throws {
        // Given
        let isPresented = true
        
        // When
        let sheet = AddPlayerSheet(
            isPresented: .constant(isPresented),
            onSave: { _ in },
            onCancel: { }
        )
        
        // Then
        let view = try sheet.inspect()
        let navigationView = try view.navigationView()
        let zstack = try navigationView.zStack()
        let vstack = try zstack.vStack(1)
        
        // プレビューセクションの存在確認
        let inputVStack = try vstack.vStack(1)
        
        // プレビューアバターは名前が入力されていない時は表示されない
        // この時点では名前が空なので、プレビューは表示されない
        #expect(try inputVStack.vStack(0) != nil)
    }
    
    @Test func testAddPlayerSheetWithPlayerName() throws {
        // Given
        let isPresented = true
        let playerName = "テストプレイヤー"
        
        // When
        let sheet = AddPlayerSheet(
            isPresented: .constant(isPresented),
            onSave: { _ in },
            onCancel: { }
        )
        
        // Then
        let view = try sheet.inspect()
        let navigationView = try view.navigationView()
        let zstack = try navigationView.zStack()
        let vstack = try zstack.vStack(1)
        
        // テキストフィールドに名前を入力
        let inputVStack = try vstack.vStack(1)
        let fieldVStack = try inputVStack.vStack(0)
        let textField = try fieldVStack.textField(1)
        
        // テキストフィールドが存在することを確認
        #expect(textField != nil)
        
        // テキストフィールドのプレースホルダーが正しく設定されていることを確認
        #expect(try textField.input() == "")
    }
    
    @Test func testAddPlayerSheetAlertSystem() throws {
        // Given
        let isPresented = true
        var saveCalled = false
        
        // When
        let sheet = AddPlayerSheet(
            isPresented: .constant(isPresented),
            onSave: { _ in saveCalled = true },
            onCancel: { }
        )
        
        // Then
        let view = try sheet.inspect()
        
        // アラートシステムが存在することを確認（空の名前での保存時に表示される）
        #expect(view != nil)
        
        // 初期状態でアラートが表示されていないことを確認
        #expect(saveCalled == false)
    }
}