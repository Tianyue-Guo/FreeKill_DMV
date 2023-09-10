// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import Fk.Pages
import Fk.RoomElement

GraphicsBox {
  id: root

  property var selected_ids: []
  property var all_options: []
  property var cards: []

  title.text: Backend.translate("$ChooseCard")
  // TODO: Adjust the UI design in case there are more than 7 cards
  width: 40 + Math.min(7, Math.max(4, cards.length)) * 100
  height: 230

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

  function processPrompt(prompt) {
    const data = prompt.split(":");
    let raw = Backend.translate(data[0]);
    const src = parseInt(data[1]);
    const dest = parseInt(data[2]);
    if (raw.match("%src")) raw = raw.replace(/%src/g, Backend.translate(getPhoto(src).general));
    if (raw.match("%dest")) raw = raw.replace(/%dest/g, Backend.translate(getPhoto(dest).general));
    if (raw.match("%arg2")) raw = raw.replace(/%arg2/g, Backend.translate(data[4]));
    if (raw.match("%arg")) raw = raw.replace(/%arg/g, Backend.translate(data[3]));
    return raw;
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

      Row {
        spacing: 7
        Repeater {
          id: to_select
          model: cards
          delegate: cardDelegate
        }
      }
    }

    Row {
      spacing: 7
      Repeater {
        model: all_options

        MetroButton {
          Layout.fillWidth: true
          text: processPrompt(modelData)
          enabled: root.selected_ids.length == 1

          onClicked: {
            close();
            roomScene.state = "notactive";
            const reply = JSON.stringify(
              {
                cards: root.selected_ids,
                choice: modelData,
              }
            );
            ClientInstance.replyToServer("", reply);
          }
        }
      }
    }
  }

  function updateCardSelectable() {
    for (let i = 0; i < cards.length; i++) {
      const item = to_select.itemAt(i);
      if (item.selected) continue;
      item.selectable = root.selected_ids.length == 0;
    }
  }

  function loadData(data) {
    const d = data;
    cards = d[0].map(cid => {
      return JSON.parse(Backend.callLuaFunction("GetCardData", [cid]));
    });
    all_options = d[1];
  }
}

