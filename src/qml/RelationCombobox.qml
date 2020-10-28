import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.12

import org.qfield 1.0
import org.qgis 1.0
import Theme 1.0

Item {
  id: relationCombobox

  Component.onCompleted: {
    comboBox.currentIndex = featureListModel.findKey(value)
    comboBox.visible = _relation !== undefined ? _relation.isValid : true
    searchButton.visible = _relation !== undefined ? _relation.isValid : true
    addButton.visible = _relation !== undefined ? _relation.isValid : false
    invalidWarning.visible = _relation !== undefined ? !(_relation.isValid) : false
  }

  anchors {
    left: parent.left
    right: parent.right
    rightMargin: 10
  }

  property var currentKeyValue: value
  onCurrentKeyValueChanged: {
    comboBox._cachedCurrentValue = currentKeyValue
    comboBox.currentIndex = featureListModel.findKey(currentKeyValue)
  }

  height: childrenRect.height + 10

  RowLayout {
    anchors { left: parent.left; right: parent.right }

    ComboBox {
      id: comboBox

      property var _cachedCurrentValue

      textRole: 'display'

      Layout.fillWidth: true

      model: featureListModel

      onCurrentIndexChanged: {
        var newValue = featureListModel.dataFromRowIndex(currentIndex, FeatureListModel.KeyFieldRole)
        valueChanged(newValue, false)
      }

      Connections {
        target: featureListModel

        function onModelReset() {
          comboBox.currentIndex = featureListModel.findKey(comboBox._cachedCurrentValue)
        }
      }

      MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true

        onClicked: mouse.accepted = false
        onPressed: { forceActiveFocus(); mouse.accepted = false; }
        onReleased: mouse.accepted = false;
        onDoubleClicked: mouse.accepted = false;
        onPositionChanged: mouse.accepted = false;
        onPressAndHold: mouse.accepted = false;
      }

      // [hidpi fixes]
      delegate: ItemDelegate {
        width: comboBox.width
        height: 36
        text: comboBox.textRole ? (Array.isArray(comboBox.model) ? modelData[comboBox.textRole] : model[comboBox.textRole]) : modelData
        font.weight: comboBox.currentIndex === index ? Font.DemiBold : Font.Normal
        font.pointSize: Theme.defaultFont.pointSize
        highlighted: comboBox.highlightedIndex == index
      }

      contentItem: Text {
        id: textLabel
        text: comboBox.displayText
        font: Theme.defaultFont
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: value === undefined || !enabled ? 'gray' : 'black'
      }

      background: Item {
        implicitWidth: 120
        implicitHeight: 36

        Rectangle {
          y: textLabel.height - 8
          width: comboBox.width
          height: comboBox.activeFocus ? 2 : 1
          color: comboBox.activeFocus ? "#4CAF50" : "#C8E6C9"
        }

        Rectangle {
          visible: enabled
          anchors.fill: parent
          id: backgroundRect
          border.color: comboBox.pressed ? "#4CAF50" : "#C8E6C9"
          border.width: comboBox.visualFocus ? 2 : 1
          color: Theme.lightGray
          radius: 2
        }
      }
      // [/hidpi fixes]
    }

    Image {
      id: searchButton

      Layout.margins: 4
      Layout.preferredWidth: 18
      Layout.preferredHeight: 18
      source: Theme.getThemeIcon("ic_baseline_search_black")
      width: 18
      height: 18
      opacity: enabled ? 1 : 0.3

      MouseArea {
        anchors.fill: parent
        onClicked: {
          searchFeaturePopup.open()
        }
      }
    }


    Image {
      Layout.margins: 4
      Layout.preferredWidth: 18
      Layout.preferredHeight: 18
      id: addButton
      source: Theme.getThemeIcon("ic_add_black_48dp")
      width: 18
      height: 18
      opacity: enabled ? 1 : 0.3

      MouseArea {
        anchors.fill: parent
        onClicked: {
            addFeaturePopup.state = 'Add'
            addFeaturePopup.currentLayer = relationCombobox._relation ? relationCombobox._relation.referencedLayer : null
            addFeaturePopup.open()
        }
      }
    }

    Text {
      id: invalidWarning
      visible: false
      text: qsTr( "Invalid relation")
      color: Theme.errorColor
    }
  }

  EmbeddedFeatureForm{
      id: addFeaturePopup

      onFeatureSaved: {
          var referencedValue = addFeaturePopup.attributeFormModel.attribute(relationCombobox._relation.resolveReferencedField(field.name))
          var index = featureListModel.findKey(referencedValue)
          if ( index < 0 ) {
            // model not yet reloaded - keep the value and set it onModelReset
            comboBox._cachedCurrentValue = referencedValue
          } else {
            comboBox.currentIndex = index
          }
      }
  }


  Popup {
    id: searchFeaturePopup

    signal cancel
    signal apply
    signal finished

    parent: ApplicationWindow.overlay
    x: 24
    y: 24
    width: parent.width - 48
    height: parent.height - 48
    padding: 0
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    focus: visible

    onOpened: {
      searchField.forceActiveFocus()
    }

    onClosed: {
      searchFeaturePopup.cancel()
      searchFeaturePopup.finished()
    }

    Page {
      anchors.fill: parent

      header: PageHeader {
        title: qsTr('Related Features')
        showApplyButton: true
        showCancelButton: true
        onApply: {
          searchFeaturePopup.close()
          searchFeaturePopup.apply()
          searchFeaturePopup.finished()
        }
        onCancel: {
          searchFeaturePopup.close()
          searchFeaturePopup.cancel()
          searchFeaturePopup.finished()
        }
      }

      TextField {
        z: 1
        id: searchField
        anchors.left: parent.left
        anchors.right: parent.right

        placeholderText: qsTr("Search…")
        placeholderTextColor: Theme.mainColor

        leftPadding: 24
        rightPadding: 24
        font: Theme.defaultFont
        selectByMouse: true
        verticalAlignment: TextInput.AlignVCenter

        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

        onDisplayTextChanged: {
          featureListModel.searchTerm = searchField.displayText
        }
      }

      Image {
        id: clearButton
        z: 1
        width: 20
        height: 20
        source: Theme.getThemeIcon("ic_clear_black_18dp")
        sourceSize.width: 20 * screen.devicePixelRatio
        sourceSize.height: 20 * screen.devicePixelRatio
        fillMode: Image.PreserveAspectFit
        anchors.top: searchField.top
        anchors.right: searchField.right
        anchors.topMargin: 12
        anchors.rightMargin: 12
        opacity: searchField.text.length > 0 ? 1 : 0.25

        MouseArea {
          anchors.fill: parent
          onClicked: {
            searchField.text = '';
          }
        }
      }

      ScrollView {
        padding: 20

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: searchField.bottom

        leftPadding: 0
        rightPadding: 0

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        contentItem: resultsList
        contentWidth: resultsList.width
        contentHeight: resultsList.height
        clip: true

        ListView {
          id: resultsList
          anchors.top: parent.top
          model: featureListModel
          width: parent.width
          height: searchFeaturePopup.height - searchField.height - 50
          clip: true

          delegate: Rectangle {
            id: delegateRect

            anchors.margins: 10
            height: radioButton.visible ? radioButton.height : checkBoxButton.height
            width: parent ? parent.width : undefined

            RadioButton {
              id: radioButton

              visible: !featureListModel.allowMulti
              checked: model.checked
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              text: displayString
              topPadding: 12
              bottomPadding: 12
              leftPadding: 24
              rightPadding: 24
              ButtonGroup.group: buttonGroup
            }

            CheckBox {
              id: checkBoxButton

              visible: featureListModel.allowMulti
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              text: displayString
              topPadding: 12
              bottomPadding: 12
              leftPadding: 24
              rightPadding: 24
            }

            /* bottom border */
            Rectangle {
              anchors.bottom: parent.bottom
              height: 1
              color: "lightGray"
              width: parent.width
            }

            MouseArea {
              anchors.fill: parent
              propagateComposedEvents: true

              onClicked: {
                var allowMulti = resultsList.model.allowMulti;
                var popupRef = searchFeaturePopup;

                // after this line, all the references get wrong, that's why we have `popupRef` defined above
                model.checked = !model.checked

                if (!allowMulti) {
                  popupRef.close()
                  popupRef.apply()
                  popupRef.finished()
                }
              }
            }
          }
        }
      }
    }
  }

  ButtonGroup { id: buttonGroup }

}
