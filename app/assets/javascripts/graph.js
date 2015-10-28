google.load('visualization', '1', {packages: ['corechart', 'line']});
google.setOnLoadCallback(drawBasic);

function areSameDate(d1, d2) {
    return d1.getFullYear() == d2.getFullYear()
        && d1.getMonth() == d2.getMonth()
        && d1.getDate() == d2.getDate();
}

function createEventTooltip(date, count, events){
  var $wrapper = $('<div>'),
      $img_field = $('<div class="thumbnail-wrapper">'),
      $wrapper_ul = $('<ul class="timeline">'),
      $event_type = $('<div class="event-type"><div class="event-circle"><i class="material-icons"></i></div></div>'),
      $event_text = $('<div class="event-text"><p></p><h5><div class="image-circle"></div></h5></div>');

  function cloneEventContent(eventType, text, name, link, image){
    var $li = $('<li>'),
        $etype = $event_type.clone(),
        $etext = $event_text.clone();

    $etype.find("div.event-circle").addClass(eventType);
    $etype.find("i").html(eventType);
    $etext.find("p").html(text);
    if(image != null){
      $etext.find("h5 .image-circle").append('<img src="' + image + '">');
    }
    if(name != null && link != null){
      $etext.find("div.image-circle").after('<a href="' + link + '">' + name + '</a>');
    }

    $li.append($etype);
    $li.append($etext);

    return $li;
  }

  $.each(events, function(i, eventObj){
    if(eventObj.event_type == "add_image"){
      if($img_field.find("div.thumbnail").length > 0){
        $wrapper_ul.append(cloneEventContent("image", "画像を追加しました。", null, null, eventObj.item.image));
      }else{
        $img_field.append('<div class="thumbnail"><img src="' + eventObj.item.image + '"></div>');
      }
    }else if(eventObj.event_type == "create_item"){
      $wrapper_ul.append(cloneEventContent("add", "アイテムを追加しました。", eventObj.item.name, eventObj.item.path, eventObj.item.image));
    }else if(eventObj.event_type == "create_list"){
      $wrapper_ul.append(cloneEventContent("add", "リストを追加しました。", eventObj.item.name, eventObj.item.path, eventObj.item.image));
    }else if(eventObj.event_type == "dump"){
      var list_or_item = (eventObj.item.is_list ? "リスト" : "アイテム");
      $wrapper_ul.append(cloneEventContent("delete", list_or_item + "を手放しました。", eventObj.item.name, eventObj.item.path, eventObj.item.image));

    }
  });
  $img_field.append('<div class="item-props"><b>' + date + '</b><br>アイテムの数: <b>' + count + '</b></div>');
  $wrapper.append($img_field);
  var a = $wrapper.append($wrapper_ul);
  return a.prop("outerHTML");
}

function convertEventObjToData(events){
  var dataArray = $.map(events, function(eventObj,i){
    var result = [],
        point = 'point { size: 18; shape-type: star; fill-color: #a52714}',
        regOfDate = /(\d+)-(\d+)-(\d+)/,
        matchedDate = eventObj.date.match(regOfDate),
        date = new Date(matchedDate[1], matchedDate[2] - 1, matchedDate[3]);
    var eee = createEventTooltip(eventObj.date, eventObj.count, eventObj.events);
    result.push([
      date,
      eventObj.count,
      (eventObj.events.length > 0),
      eee
    ]);

    return result;
  });

  // 表示した日のデータがなければ付け加える
  var last = dataArray[dataArray.length - 1],
      today = new Date();
  if(!areSameDate(last[0], today)){
    dataArray.push([new Date(today.getFullYear(), today.getMonth(), today.getDate()), last[1], false, null]);
  }

  return dataArray;
}

function drawBasic() {
      if(typeof gon == "undefined"){
        return;
      }
      var dataArray = convertEventObjToData(gon.item);

      var data = new google.visualization.DataTable();
      data.addColumn('date', 'day');
      data.addColumn('number', 'アイテムの数');
data.addColumn('boolean', 'イベント');
      data.addColumn({type: 'string', role: 'tooltip', 'p':{'html': true}});

      data.addRows(dataArray);

      // http://stackoverflow.com/questions/20193233/google-line-charts-place-circle-on-annotation
      var view = new google.visualization.DataView(data);
      view.setColumns([0, 1, {
          type: 'number',
          label: data.getColumnLabel(2),
          calc: function (dt, row) {
              // return the value in column 1 when column 2 is true
              return (dt.getValue(row, 2)) ? dt.getValue(row, 1) : null;
          }
      }, 3]);

      var width = $("#chart").parent().parent().outerWidth();

      var options = {
        legend: 'none',
        height: 350,
        width: width,
        hAxis: {
          title: '日にち'
        },
        vAxis: {
          title: 'リスト内のモノの数',
          minValue: 0
        },
        tooltip: {
            isHtml: true
        },
series: {
            0: {
                // put any options pertaining to series 0 ("Run-rate") here
            },
            1: {
                // put any options pertaining to series 1 ("Wicket Falls") here
                pointSize: 8,
                lineWidth: 0
            }
        }
      };

      var chart = new google.visualization.LineChart(document.getElementById('chart'));

      chart.draw(view, options);
}
