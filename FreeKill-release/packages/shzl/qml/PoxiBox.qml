// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import Fk.Pages
import Fk.RoomElement

GraphicsBox {
  id: root
  title.text: Backend.translate("#poxi-choose")
  // TODO: Adjust the UI design in case there are more than 7 cards
  width: 70 + Math.min(7, Math.max(1, hand1.length, hand2.length)) * 100
  height: 50 + (hand1.length > 0 ? 150 : 0) + (hand2.length > 0 ? 150 : 0)

  property var selected_ids: []

  property string myGeneral: ""
  property string yourGeneral: ""

  property var hand1: []
  property var hand2: []

  Component {
    id: cardDelegate
    CardItem {
      Component.onCompleted: {
        setData(modelData);
      }
      autoBack: false
      selectable: true
      onSelectedChanged: {
        if (selected) {
          origY = origY - 20;
          root.selected_ids.push(cid);
        } else {
          origY = origY + 20;
          root.selected_ids.splice(root.selected_ids.indexOf(cid), 1);
        }
        origX = x;
        goBack(true);
        root.selected_idsChanged();
        root.updateCardSelectable();
      }
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.topMargin: 40
    anchors.leftMargin: 20
    anchors.rightMargin: 20
    anchors.bottomMargin: 20

    Row {
      height: 130
      spacing: 15

      Rectangle {
        border.color: "#A6967A"
        radius: 5
        color: "transparent"
        width: 18
        height: parent.height

        Text {
          color: "#E4D5A0"
          text: Backend.translate(myGeneral)
          anchors.fill: parent
          wrapMode: Text.WrapAnywhere
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
          font.pixelSize: 15
        }
      }

      Row {
        spacing: 7
        Repeater {
          id: handcards1
          model: hand1
          delegate: cardDelegate
        }
      }
    }

    Row {
      height: 130
      spacing: 15

      Rectangle {
        border.color: "#A6967A"
        radius: 5
        color: "transparent"
        width: 18
        height: parent.height

        Text {
          color: "#E4D5A0"
          text: Backend.translate(yourGeneral)
          anchors.fill: parent
          wrapMode: Text.WrapAnywhere
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
          font.pixelSize: 15
        }
      }

      Row {
        spacing: 7
        Repeater {
          id: handcards2
          model: hand2
          delegate: cardDelegate
        }
      }
    }

    Row {
      MetroButton {
        text: Backend.translate("OK")
        enabled: root.selected_ids.length == 4
        onClicked: {
          close();
          ClientInstance.replyToServer("", JSON.stringify(root.selected_ids));
        }
      }
      MetroButton {
        text: Backend.translate("Cancel")
        enabled: true
        onClicked: {
          close();
          ClientInstance.replyToServer("", "");
        }
      }
    }
  }

  function updateCardSelectable() {
    for (let i = 0; i < hand1.length; i++) {
      const item1 = handcards1.itemAt(i);
      if (item1.selected) continue;
      item1.selectable = !root.selected_ids.find(id => {
        const data = JSON.parse(Backend.callLuaFunction("GetCardData", [id]));
        return item1.suit === data.suit;
      });
    }
    for (let i = 0; i < hand2.length; i++) {
      const item1 = handcards2.itemAt(i);
      if (item1.selected) continue;
      item1.selectable = !root.selected_ids.find(id => {
        const data = JSON.parse(Backend.callLuaFunction("GetCardData", [id]));
        return item1.suit === data.suit;
      });
    }
  }

  function loadData(data) {
    const d = data;
    myGeneral = d[0];
    hand1 = d[1].map(cid => {
      return JSON.parse(Backend.callLuaFunction("GetCardData", [cid]));
    });
    yourGeneral = d[2];
    hand2 = d[3].map(cid => {
      return JSON.parse(Backend.callLuaFunction("GetCardData", [cid]));
    });
  }
}

