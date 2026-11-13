// documentmd.online: меню, выбор мессенджера, форма заявки
(function(){
  var PHONE='37377582929', TG='infodocumentmd';
  function link(via,q){
    var t=encodeURIComponent(q||'');
    if(via==='whatsapp') return 'https://wa.me/'+PHONE+(q?'?text='+t:'');
    if(via==='telegram') return 'https://t.me/'+TG+(q?'?text='+t:'');
    if(via==='viber') return 'viber://chat?number=%2B'+PHONE+(q?'&draft='+t:'');
    return '#contacts';
  }
  function copy(q){ try{ if(q&&navigator.clipboard) navigator.clipboard.writeText(q); }catch(e){} }

  // шапка
  var h=document.querySelector('.hdr'), b=document.querySelector('.burger');
  if(b){ b.addEventListener('click',function(){var o=h.classList.toggle('open');b.setAttribute('aria-expanded',o);});
    h.querySelectorAll('.nav a').forEach(function(a){a.addEventListener('click',function(){h.classList.remove('open');b.setAttribute('aria-expanded',false);});}); }
  var y=document.getElementById('y'); if(y) y.textContent=new Date().getFullYear();

  // плавающее меню связи
  var fw=document.getElementById('fab'), curQ='';
  function setQ(q){ curQ=q||''; if(!fw) return;
    fw.querySelectorAll('[data-via]').forEach(function(a){a.href=link(a.getAttribute('data-via'),curQ);}); }
  function openFab(o){ if(!fw) return; fw.classList.toggle('open',o); fw.querySelector('.fab').setAttribute('aria-expanded',o); if(!o) setQ(''); }
  if(fw){
    fw.querySelector('.fab').addEventListener('click',function(){ openFab(!fw.classList.contains('open')); });
    fw.querySelectorAll('.fab-menu a').forEach(function(a){a.addEventListener('click',function(){ if(curQ) copy(curQ); setTimeout(function(){openFab(false);},50); });});
    document.addEventListener('click',function(e){ if(!fw.contains(e.target)&&!e.target.closest('.js-msg')) openFab(false); });
    document.addEventListener('keydown',function(e){ if(e.key==='Escape') openFab(false); });
  }
  // кнопки «быстрый вопрос»: открывают меню выбора мессенджера с готовым текстом
  document.querySelectorAll('.js-msg').forEach(function(a){
    a.addEventListener('click',function(e){ if(!fw) return; e.preventDefault(); setQ(a.getAttribute('data-q')); openFab(true); });
  });

  // форма
  var f=document.getElementById('lead');
  if(f){
    var msg=f.querySelector('.form-msg');
    f.addEventListener('submit',function(e){
      e.preventDefault();
      var d={}, ok=true;
      ['name','contact','topic','message','company'].forEach(function(n){ d[n]=(f.elements[n].value||'').trim(); });
      d.via=f.elements.via.value; d.consent=f.elements.consent.checked; d.page=location.pathname; d.ref=document.referrer||'';
      ['name','contact','message'].forEach(function(n){ var bad=!d[n]; f.elements[n].classList.toggle('bad',bad); if(bad) ok=false; });
      if(!d.consent){ ok=false; }
      if(!ok){ msg.className='form-msg err'; msg.textContent=d.consent?'Заполните выделенные поля.':'Отметьте согласие на обработку данных.'; return; }
      var btn=f.querySelector('button[type=submit]'); btn.disabled=true; msg.className='form-msg'; msg.textContent='Отправляем…';
      var text='Здравствуйте! Меня зовут '+d.name+'. Тема: '+d.topic+'. '+d.message;
      var url=d.via!=='none'?link(d.via,text):'';
      var w=null; if(d.via==='whatsapp'||d.via==='telegram'){ w=window.open('about:blank','_blank'); }
      fetch('/api/lead',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(d)})
        .then(function(r){ if(!r.ok) throw 0; return r.json(); })
        .then(function(){
          f.classList.add('sent'); msg.className='form-msg ok';
          msg.textContent=url?'Заявка отправлена. Открываем мессенджер с вашим вопросом…':'Заявка отправлена. Мы свяжемся с вами.';
          if(url){ copy(text); if(w) w.location=url; else location.href=url;
            var a=document.createElement('div'); a.className='after';
            a.innerHTML='<a class="btn btn-blue" href="'+url+'" target="_blank" rel="noopener">Открыть мессенджер ещё раз</a><span style="color:#5E6679;font-size:14px">Текст вопроса скопирован: если он не подставился, вставьте его в чат.</span>';
            f.appendChild(a); }
        })
        .catch(function(){ if(w) w.close(); btn.disabled=false; msg.className='form-msg err';
          msg.textContent='Не удалось отправить. Напишите нам в мессенджер или позвоните: +373 775 82 929.'; });
    });
  }

  // появление при прокрутке
  var els=document.querySelectorAll('.rv');
  if('IntersectionObserver' in window){
    var io=new IntersectionObserver(function(es){es.forEach(function(e){if(e.isIntersecting){e.target.classList.add('on');io.unobserve(e.target);}});},{threshold:.12});
    els.forEach(function(e){io.observe(e);});
  } else els.forEach(function(e){e.classList.add('on');});
})();
