pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config

import qs.modules.common 
import qs.modules.services

PanelWindow {
    id: launcher

    readonly property int rowHeight: 44
    readonly property int maxVisibleRows: 8

    property bool open: false
    property string query: ""
    property int selected: 0
    
    readonly property string clipPrefix: ";"
    readonly property bool clipMode: launcher.query.startsWith(launcher.clipPrefix)

    property var results: {
        if (launcher.clipMode) {
            const q = launcher.query.slice(launcher.clipPrefix.length).trim();
            if (!q.length)
                return Cliphist.entries;
            
            return Cliphist.entries.map(e => ({
                        entry: e,
                        s: launcher.matchScore(Cliphist.clean(e), q)
                    })).filter(r => r.s >= 0).sort((a, b) => b.s - a.s).map(r => r.entry);
        }

        if (!launcher.query.length)
            return launcher.apps;
        
        console.log(launcher.query)
        return launcher.apps.map(e => ({
                    entry: e,
                    s: launcher.matchScore(e.name, launcher.query)
                })).filter(r => r.s >= 0).sort((a, b) => b.s - a.s).map(r => r.entry);
    }
    

    property var apps: {
        const seen = new Set();
        const out = [];
        for (const e of Array.from(DesktopEntries.applications.values)) {
            if (seen.has(e.id))
                continue;
            seen.add(e.id);
            out.push(e);
        }
        out.sort((a, b) => a.name.localeCompare(b.name));
        return out;
    }

    function matchScore(name, q) {
        name = name.toLowerCase();
        q = q.toLowerCase();
        const idx = name.indexOf(q);
        if (idx === 0)
            return 100;
        if (idx > 0)
            return 50 - idx;

        let ni = 0;
        for (let qi = 0; qi < q.length; qi++) {
            ni = name.indexOf(q[qi], ni);
            if (ni === -1)
                return -1;
            ni++;
        }
        return 10;
    }

    function activate(item) {
        if (!item)
            return;

        if (launcher.clipMode)
            Cliphist.paste(item);
        
        else
            item.execute();
        
        launcher.open = false
    }

    function reset() {
        query = "";
        selected = 0;
        searchField.text = "";
    }

    function show(prefill, forcedScreen) {
        launcher.targetScreen = forcedScreen ?? (Array.from(Quickshell.screens).find(s => s.name === (Hyprland.focusedMonitor?.name ?? "")) ?? Quickshell.screens[0]);

        reset();


        if (prefill !== undefined)
            searchField.text = prefill;
        launcher.open = true;
        Qt.callLater(() => searchField.forceActiveFocus());
    }
      
    function findInnermostBracket (arr,indexofthis){
        // find the smallest brac and return the calcation and the index of it  
    if(arr.includes('(')){
        return findInnermostBracket(arr.slice(arr.indexOf('(') + 1 ,arr.length),indexofthis + arr.indexOf('(') + 1)
    }
    else{
        if(arr.includes(')')) {
        return {data: arr.slice(0, arr.indexOf(')')), index:indexofthis}}
        return  {data: arr, index:indexofthis}
    }
    }


    function pre(oper,index) {
            let operation = oper[index];
            let {before, after,prev , nextopindex} = findbeforeafter(oper,operation,index);
            let indexofeqa= (prev === -1 ? 0 : prev)
            let endofeqa = (nextopindex - indexofeqa - 1)
            return {replace: performOperation(operation, before, after).toString(),start:indexofeqa,end:endofeqa};
            }

    function performOperation(operation, firstnum, secondnum) {
    let result = 0;
    
    switch (operation) {
        case "+":
        result = +firstnum + +secondnum;
        break;
        case "-":
        result = +firstnum - +secondnum;
        break;
        case "×":
        result = +firstnum * +secondnum;
        break;
        case "÷":
        result = +firstnum / +secondnum;
        break;
    }
    if(result.toString().length >= 17){
        form.innerHTML = "Too Big"
        hold.innerHTML = ''
        setTimeout(()=> {
        form.innerHTML = ''
        },2000)
    
    }
    return result;
    }

    function findNextOperator(arr, operation, indexarr) {
    for (let i = indexarr; i < arr.length; i++) {
        if (isNaN(+arr[i]) && i !== indexarr) {
            return i;  // Return index of the next operator
        }
    }
    return arr.length;
    } 

    function findPreviousOperator(arr, operation, indexarr) {
        for (let i = indexarr; i >= 0; i--) {
        if (isNaN(+arr[i]) && i !== indexarr) {
            return i;  // Return index of the first number of the equation
        }else if(indexarr == 0){
            return 'isolatiedop';
        }
    }
        return -1;
    }

    function findbeforeafter(operations, operation, index) {
    let prevopin = findPreviousOperator(operations, operation, index);
    let nextopindex = findNextOperator(operations, operation, index);
    let gropednum;
    let secondnum;
    if (nextopindex  == operations.length) {
            secondnum = operations.slice(index + 1).join('').replaceAll(",", "");
    } else {
        if(prevopin == 'isolatiedop'){
                gropednum = operations.slice(0, nextopindex).join().replaceAll(",", "");
                operations[0] = gropednum
                operations.splice(1, nextopindex - 1)
                prevopin = prevopin   
    }
        secondnum = operations.slice(index + 1, nextopindex).join('').replaceAll(",", "");}
        gropednum = operations.slice(prevopin + 1, index).join().replaceAll(",", "");
    return { before: gropednum, after: secondnum , prev: (prevopin + 1) ,nextopindex: nextopindex  }; 
    }

    function checkForDuplicate(operations){
    let newop = []
    for(let i =0; i < operations.length;i++){
        if(operations[i] === operations[i + 1] && isNaN(+operations[i]) && !('()'.includes(operations[i]))){
        if(!'+-'.includes(newop[newop.length - 1])){
            newop.push(operations[i] == '-' ? "+": '+')
        }
        i++
        }else {

        if((operations[i] == newop[newop.length - 1]  && isNaN(+operations[i]))){
            
        }else{
            newop.push(operations[i])
        }
        }
    }
    return newop
    }

    function compine(operations){
    let newop = []
    for(let i =0; i < operations.length;i++){
        if('-+'.includes(operations[i - 1]) && '×÷+-'.includes(operations[i - 2])){
        newop[i - 1] = operations[i - 1] + operations[i]
        i++
        }else{
        newop.push(operations[i])
        }
    }
    return newop
    }

    function evaluateExpression(operations) {
          operations = operations[0].replaceAll(" ", "").replaceAll('−',"-").replaceAll('*','×').replaceAll('/','÷').split('');
          operations = checkForDuplicate(operations)
          operations = compine(operations)
          for (let i = 0; i < operations.length; i++) {
            let indexofeqa = 0;
            let endofeqa = 0;
            let replacement = "";
            let divideexis = operations.join('').includes("÷");
            let multiexis = operations.join('').includes("×");
            let havebrac = operations.join('').includes("(")
            if (operations[i] == "(") {
              const remainingArray = operations.slice(i + 1, operations.length);
              let endofbrac;
              remainingArray.pop()
              let {data,index} = findInnermostBracket(remainingArray,i)
              let length = data.length + 1
              data = [data.join('')]
              let result = evaluateExpression(data)
              if (result != []) {
                operations[index] = result[0];
                operations.splice(index + 1 , length )
                result = "";
                i = 0;
              }
              
        } else if ((divideexis || multiexis) && !havebrac) {
            let indexoffirstdivide = operations.indexOf("÷");
            let indexoffirstmulti = operations.indexOf("×");
            if (divideexis && multiexis) {
              if (indexoffirstdivide < indexoffirstmulti) {
                let data = pre(operations,indexoffirstdivide)
                indexofeqa = data.start 
                endofeqa = data.end
                replacement = data.replace
              }else{
                let data = pre(operations,indexoffirstmulti)
                indexofeqa = data.start 
                endofeqa = data.end 
                replacement = data.replace
              }
            }
            else if(divideexis && !multiexis){
              let data = pre(operations,indexoffirstdivide)
              indexofeqa = data.start 
              endofeqa = data.end 
              replacement = data.replace  
            }
            else{
              let data = pre(operations,indexoffirstmulti)
              indexofeqa = data.start
              endofeqa = data.end ;
              replacement = data.replace
            }
            } 
          else if (isNaN(+operations[i]) && "+−-".includes(operations[i]) && !havebrac ) {
              let data = pre(operations,i)
              indexofeqa = data.start
              endofeqa = data.end;
              replacement = data.replace
            }
            if (replacement !== '') {
              operations[indexofeqa] = replacement;
              operations.splice(indexofeqa + 1, endofeqa);
              replacement = "";
              indexofeqa = 0;
              endofeqa = 0;
              i = 0;
            }
          }
          if(operations.length > 1){
            operations = [operations.join('').replaceAll(',',"")]
            return evaluateExpression(operations) 
        }else{
          return operations;
        }
      }

    function launch(entry) {
        if (!entry)
            return;
        entry.execute();
        launcher.open = false;
    }

    property var targetScreen: Quickshell.screens[0]
    screen: launcher.targetScreen

    visible: launcher.open
    WlrLayershell.namespace: "quickshell:launcher"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: launcher.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }



    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (launcher.open)
                launcher.open = false;
            else
                launcher.show();
        }
        function open(): void {
            launcher.show();
        }
        function close(): void {
            launcher.open = false;
        }
    }

    Connections {
        target: ClipboardState

         function onOpenRequested(targetScreen) {
            launcher.show(launcher.clipPrefix, targetScreen);
        }

        function onCloseRequested() {
            launcher.open = false;
        }
    }

     Binding {
        target: ClipboardState
        property: "active"
        value: launcher.open && launcher.clipMode
    }

    Binding {
        target: ClipboardState
        property: "screen"
        value: launcher.targetScreen
    }

    MouseArea {
        anchors.fill: parent
        onClicked: launcher.open = false
    }

    Rectangle {
        id: card

        width: 560
        height: Math.max(rowHeight + 24, Math.min(rowHeight + 24 + resultsList.count * launcher.rowHeight, rowHeight + 24 + launcher.maxVisibleRows * launcher.rowHeight))
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.2

        radius: Appearance.radius
        color: Qt.rgba(Appearance.bg.r, Appearance.bg.g, Appearance.bg.b, 0.92)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        opacity: launcher.open ? 1 : 0
        scale: launcher.open ? 1 : 0.97
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animMed
                easing.type: Appearance.easeOutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Appearance.animMed
                easing.type: Appearance.easeOutCubic
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: Appearance.animFast
                easing.type: Appearance.easeOutCubic
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Appearance.shadowColor
            shadowBlur: Appearance.shadowBlur / 32
            shadowVerticalOffset: Appearance.shadowOffsetY * 1.6
            blurEnabled: false
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Appearance.radius
            anchors.rightMargin: Appearance.radius
            height: 1
            color: Qt.rgba(1, 1, 1, 0.1)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            RowLayout {
                id: searchRow
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: launcher.rowHeight
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 10

                MaterialSymbol {
                    icon: launcher.clipMode ? "content_paste" : "search"
                    color: Appearance.accent
                    opacity: 0.9
                    iconSize: 19
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        text: launcher.clipMode ? "Search clipboard…" : "Search apps…"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        color: Appearance.fg
                        opacity: 0.35
                        font.pixelSize: 17
                        font.weight: Font.Medium
                        font.family: Appearance.fontFamily
                        visible: !searchField.text.length
                    }

                    TextInput {
                        id: searchField
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        color: Appearance.fg
                        font.pixelSize: 17
                        font.weight: Font.Medium
                        font.family: Appearance.fontFamily
                        clip: true
                        selectByMouse: true

                        onTextChanged: {
                            launcher.query = text;
                            launcher.selected = 0;
                        }

                        Keys.onEscapePressed: launcher.open = false
                        Keys.onUpPressed: launcher.selected = Math.max(0, launcher.selected - 1)

                        Keys.onDownPressed: launcher.selected = Math.min(launcher.results.length - 1, launcher.selected + 1)
                        Keys.onReturnPressed: launcher.activate(launcher.results[launcher.selected])
                        Keys.onEnterPressed: launcher.activate(launcher.results[launcher.selected])
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: 1
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                color: Appearance.hairline
                visible: resultsList.count > 0
            }

            ListView {
                id: resultsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: launcher.results
                currentIndex: launcher.selected

                delegate: Item {
                    id: row

                    required property var modelData
                    required property int index

                    width: resultsList.width
                    height: launcher.rowHeight

                    readonly property bool isSelected: row.index === launcher.selected

                    Rectangle {
                        id: selectionChip
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        anchors.topMargin: 2
                        anchors.bottomMargin: 2
                        radius: Appearance.pillRadius
                        color: row.isSelected ? Appearance.accentContainer : Appearance.fg
                        opacity: row.isSelected ? 1 : (hover.hovered ? 0.06 : 0)

                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.animFast
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Appearance.animFast
                            }
                        }

                        Rectangle {
                            visible: row.isSelected
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.topMargin: 1
                            anchors.leftMargin: selectionChip.height / 2
                            anchors.rightMargin: selectionChip.height / 2
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.14)
                        }
                    }

                    HoverHandler {
                        id: hover
                        onHoveredChanged: if (hovered)
                            launcher.selected = row.index
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 12

                        IconImage {
                            visible: !launcher.clipMode
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            source: launcher.clipMode ? "" : Quickshell.iconPath(row.modelData.icon, "image-missing")
                        }

                        MaterialSymbol {
                            visible: launcher.clipMode
                            icon: "content_copy"
                            iconSize: 17
                            color: row.isSelected ? Appearance.onAccentContainer : Appearance.fg
                            opacity: 0.5
                        }

                        Text {
                            Layout.fillWidth: true
                            text: launcher.clipMode ? Cliphist.clean(row.modelData).replace(/\s+/g, " ") : row.modelData.name
                            color: row.isSelected ? Appearance.onAccentContainer : Appearance.fg
                            font.weight: row.isSelected ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                            font.family: Appearance.fontFamily
                            font.pixelSize: 13

                            Behavior on color {
                                ColorAnimation {
                                    duration: Appearance.animFast
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: launcher.activate(row.modelData)
                    }

                Text {
                    anchors.centerIn: parent
                    visible: resultsList.count === 0
                    text: "No results"
                    color: Appearance.fg
                    opacity: 0.4
                    font.family: Appearance.fontFamily
                    font.pixelSize: 13
                }
            }
        }
    }
}
}
