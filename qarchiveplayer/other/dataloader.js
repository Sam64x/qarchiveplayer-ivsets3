WorkerScript.onMessage = function(msg) {
    var prevCount, prevCheckSum

    var dateCheckSum = 0
    if (msg.type === "loadEvents")
    {
        prevCount = msg.model.count
        prevCheckSum = msg.sum
        msg.model.clear()
        if (msg.jsonStr === "") {
            msg.model.sync()
            return
        }
        else {
            var jsonData = JSON.parse(msg.jsonStr)
            if (jsonData.length === 0){
                msg.model.sync()
                return;
            }
            else {
                var j, startDate, finishDate, value, color
                var fl = msg.filter
                for (j = 0; j < jsonData.length; j++)
                {
                    var typeId = parseInt(jsonData[j]["typeid"])
                    var containsId = fl.indexOf(typeId) > -1
                    if (fl.length === 0 || containsId)
                    {
                        dateCheckSum += startDate / 30000*(j+1)

                        startDate = new Date(jsonData[j]["s"])
                        finishDate = new Date(jsonData[j]["f"])

                        var groupId = parseInt(jsonData[j]["typeid"].charAt(0))
                        color = groupId === 2 ? "red" : "#05f7ff"
                        msg.model.append({
                                             "s":startDate,
                                             "f":finishDate,
                                             "v": 100,
                                             "color": color,
                                             "comment": jsonData[j]["comment"],
                                             "type": typeId
                                         })
                    }
                }
            }
        }
    }
    if (msg.type === "loadFullness")
    {
        prevCount = msg.model.count
        prevCheckSum = msg.sum
        msg.model.clear()
        var colorType = ["006699", "1c871a", "a86d19", "a4b304"];
        if (msg.jsonStr === "") {
            msg.model.sync()
            return
        }
        else {
            var jsonData = JSON.parse(msg.jsonStr)
            if (jsonData.length === 0){
                msg.model.sync()
                return;
            }
            else {
                var i, j, startDate, finishDate, arcType, item;
                if (msg.view === 0){
                    for(j = 1; j < jsonData.length; j++) {
                        startDate = new Date(jsonData[j-1].d)
                        finishDate = new Date(jsonData[j].d)
                        arcType = jsonData[j].colorType

                        var opacity = parseInt((Math.sqrt(jsonData[j-1].v/100) * 255)).toString(16)
                        opacity = opacity.length < 2 ? ("0"+opacity) : opacity
                        if (j === 0 || j === jsonData.length-1 || j === jsonData.length/2) dateCheckSum += startDate/3000
                        msg.model.append({"s":startDate, "f":finishDate, "color1":("#"+opacity+colorType[arcType])})
                    }
                }
                else if (msg.view === 1 || msg.view === 2){ // месяц или неделя
                    for(j = 1; j < jsonData.length; j++) {
                        startDate = new Date(jsonData[j-1].d)
                        finishDate = new Date(jsonData[j].d)
                        arcType = jsonData[j].colorType

                        var timezone = new Date().getTimezoneOffset()
                        startDate.setMinutes(startDate.getMinutes() - timezone)
                        finishDate.setMinutes(finishDate.getMinutes() - timezone)

                        opacity = parseInt((Math.sqrt(jsonData[j-1].v/100) * 255)).toString(16)
                        opacity = opacity.length < 2 ? ("0"+opacity) : opacity
                        if (j === 0 || j === jsonData.length-1 || j === jsonData.length/2) dateCheckSum += startDate/3000
                        msg.model.append({"s":startDate, "f":finishDate, "color1":("#"+opacity+colorType[arcType])})
                    }
                }
                else {
                    for(j = 0; j < jsonData.length; j++) {
                        startDate = jsonData[j][1]
                        finishDate = jsonData[j][2]
                        arcType = jsonData[j][0]

                        var count = 0
                        var zz = ""
                        for (var i = 0; i < startDate.length; i++){
                            if (count === 3) zz += startDate[i]
                            if (startDate[i] === ":") count++
                        }
                        startDate = new Date(startDate)
                        startDate.setMilliseconds(parseInt(zz))

                        count = 0
                        zz = ""

                        for (var i = 0; i < finishDate.length; i++){
                            if (count === 3) zz += finishDate[i]
                            if (finishDate[i] === ":") count++
                        }
                        finishDate = new Date(finishDate)
                        finishDate.setMilliseconds(parseInt(zz))

                        if (j === 0 || j === jsonData.length-1 || j === jsonData.length/2) dateCheckSum += startDate/3000
                        msg.model.append({"s":startDate, "f":finishDate, "color1":("#"+colorType[arcType])})
                    }
                }
            }
        }

    }
    // проверяем изменилось ли что-то в модели
    if (msg.type === "loadFullness" || msg.type === "loadEvents"){
        if (msg.model.count !== prevCount && dateCheckSum !== prevCheckSum)
        {
            // console.log(msg.type, "UPDATE MODEL !!!")
            WorkerScript.sendMessage({'dateCheckSum': dateCheckSum, "type":msg.type})
            WorkerScript.sendMessage({'ready': true, "type":msg.type})
            msg.model.sync()
        }
    }
    if (msg.type === "loadFullnessFromModel"){
        if (msg.sourceModel!== null && msg.sourceModel.count > 0){
            var prevTargetCount = msg.targetModel.count
            msg.targetModel.clear()
            for (var i = 0; i < msg.sourceModel.count; i++){
                var start = msg.sourceModel.get(i)["s"];
                var end = msg.sourceModel.get(i)["f"]
                var color1 = msg.sourceModel.get(i)["color1"];

                var itemStartTime = msg.startDate
                var itemFinishTime = msg.endDate;
                var startPosition = 0, finishPosition = 0;

                var itemTime = itemFinishTime.getTime() - itemStartTime.getTime()
                var now = new Date()

                // основные моменты:
                // - элемент заполненности имеет начало и конец
                // - элемента списка (делегат) также имеет начало и конец
                // - конец и/или начало делегата могут быть в будущем
                //   (здесь стоит обрабатывать только случай когда конец в будущем)

                // если элемент заполненности внутри делегата
                if (start > itemStartTime && end < itemFinishTime){
                    startPosition = (start.getTime() - itemStartTime.getTime()) / itemTime
                    if (start.getTime() > now.getTime())
                        continue
                    if (end.getTime() < now.getTime())
                        finishPosition = (end.getTime() - itemStartTime.getTime()) / itemTime
                    else
                        finishPosition = (now.getTime() - itemStartTime.getTime()) / itemTime
                }
                // если элемент начинается внутри делегата, но заканчивается позже
                else if (start >= itemStartTime && start < itemFinishTime && end >= itemFinishTime){
                    startPosition = (start.getTime() - itemStartTime.getTime()) / itemTime
                    if (start.getTime() > now.getTime())
                        continue
                    if (end.getTime() < now.getTime())
                        finishPosition = 1
                    else
                        finishPosition = (now.getTime() - itemStartTime.getTime()) / itemTime
                }
                // если элемент начинается раньше делегата, но заканчивается внутри
                else if (start <= itemStartTime && end > itemStartTime && end <= itemFinishTime){
                    startPosition = 0
                    if (start.getTime() > now.getTime())
                        continue
                    if (end.getTime() < now.getTime())
                        finishPosition = (end.getTime() - itemStartTime.getTime()) / itemTime
                    else
                        finishPosition = (now.getTime() - itemStartTime.getTime()) / itemTime
                }
                // если элемент заполненности больше делегата
                else if (start <= itemStartTime && end >= itemFinishTime){
                    startPosition = 0
                    if (start.getTime() > now.getTime())
                        continue
                    if (end.getTime() < now.getTime())
                        finishPosition = 1
                    else
                        finishPosition = (now.getTime() - itemStartTime.getTime()) / itemTime
                }
                else continue
                msg.targetModel.append({"s":startPosition, "f":finishPosition, "color1":color1})
            }
            WorkerScript.sendMessage({'drawFulless':true})
            msg.targetModel.sync()
        }
    }
    if (msg.type === "loadEventsFromModel"){
        if (msg.sourceModel!== null && msg.sourceModel.count > 0){
            prevTargetCount = msg.targetModel.count
            msg.targetModel.clear()

            for (var i = 0; i < msg.sourceModel.count; i++)
            {
                var start = msg.sourceModel.get(i)["s"]
                var end = msg.sourceModel.get(i)["f"]
                var itemStartTime = msg.startDate
                var itemFinishTime = msg.endDate
                var itemTime = itemFinishTime.getTime() - itemStartTime.getTime()
                var startPosition = 0
                var finishPosition = 0

                // если элемент внутри делегата
                if (start > itemStartTime && end < itemFinishTime){
                    startPosition = (start.getTime() - itemStartTime.getTime()) / itemTime
                    finishPosition = (end.getTime() - itemStartTime.getTime()) / itemTime
                }
                // если элемент начинается внутри делегата, но заканчивается позже
                else if (start >= itemStartTime && start < itemFinishTime && end >= itemFinishTime){
                    startPosition = (start.getTime() - itemStartTime.getTime()) / itemTime
                    finishPosition = 1
                }
                // если элемент начинается раньше делегата, но заканчивается внутри
                else if (start <= itemStartTime && end > itemStartTime && end <= itemFinishTime){
                    startPosition = 0
                    finishPosition = (end.getTime() - itemStartTime.getTime()) / itemTime
                }
                // если элемент больше делегата
                else if (start <= itemStartTime && end >= itemFinishTime){
                    startPosition = 0
                    finishPosition = 1
                }
                else continue

                msg.targetModel.append({"s":startPosition,
                                           "f":finishPosition,
                                           "startDate": start,
                                           "v": msg.sourceModel.get(i)["v"],
                                           "color": msg.sourceModel.get(i)["color"],
                                           "comment":msg.sourceModel.get(i)["comment"],
                                           "type": msg.sourceModel.get(i)["type"],
                                           "visible": msg.sourceModel.get(i)["visible"]
                                       })
            }
            WorkerScript.sendMessage({'drawEvents':true})
            msg.targetModel.sync()
        }
    }
}
