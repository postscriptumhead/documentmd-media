// documentmd.online: меню, ссылки WhatsApp с готовым текстом, анимация появления
(function(){
  var PHONE='37377582929';
  document.querySelectorAll('.js-wa').forEach(function(a){
    var q=a.getAttribute('data-q'); if(q) a.href='https://wa.me/'+PHONE+'?text='+encodeURIComponent(q);
    a.target='_blank'; a.rel='noopener';
  });
  var h=document.querySelector('.hdr'), b=document.querySelector('.burger');
  if(b){ b.addEventListener('click',function(){var o=h.classList.toggle('open');b.setAttribute('aria-expanded',o);});
    h.querySelectorAll('.nav a').forEach(function(a){a.addEventListener('click',function(){h.classList.remove('open');b.setAttribute('aria-expanded',false);});}); }
  var y=document.getElementById('y'); if(y) y.textContent=new Date().getFullYear();
  var els=document.querySelectorAll('.rv');
  if('IntersectionObserver' in window){
    var io=new IntersectionObserver(function(es){es.forEach(function(e){if(e.isIntersecting){e.target.classList.add('on');io.unobserve(e.target);}});},{threshold:.12});
    els.forEach(function(e){io.observe(e);});
  } else els.forEach(function(e){e.classList.add('on');});
})();
