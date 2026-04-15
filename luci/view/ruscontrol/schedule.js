'use strict';
'require view';

return view.extend({
    render: function() {
        var isDark = false;
        try {
            var bg = window.getComputedStyle(document.body).backgroundColor;
            var m = bg.match(/\d+/g);
            if (m && (parseInt(m[0])+parseInt(m[1])+parseInt(m[2])) < 384) isDark = true;
        } catch(e) {}
        var bgColor = isDark ? '#1e1e2e' : '#f5f5f5';
        var container = E('div', { 
            class: 'cbi-map', 
            style: 'background:' + bgColor + ';padding:0;margin:0;'
        }, [
            E('div', { 
                class: 'cbi-section', 
                style: 'background:' + bgColor + ';padding:0;margin:0;'
            }, [
                E('iframe', {
                    src: '/cgi-bin/schedule' + (isDark ? '?theme=dark' : '?theme=light'),
                    style: 'width:100%;height:800px;border:none;background:' + bgColor + ';display:block;'
                })
            ])
        ]);
        return container;
    },
    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
