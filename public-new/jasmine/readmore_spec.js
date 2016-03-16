describe('$.fn.readmore', function() {

  beforeEach(function() {
    var $emma = affix('#emma');

    $emma.affix("p").html("Emma Woodhouse, handsome, clever, and rich, with a comfortable home and happy disposition, seemed to unite some of the best blessings of existence; and had lived nearly twenty-one years in the world with very little to distress or vex her.");
    $emma.affix("p").html("She was the youngest of the two daughters of a most affectionate, indulgent father, and had, in consequence of her sister's marriage, been mistress of his house from a very early period. <span class='triggerwarning'>Her mother had died too long ago for her to have more than an indistinct remembrance of her caresses</span>, and her place had been supplied by an excellent woman as governess, who had fallen little short of a mother in affection.");
  });

  it("breaks text into less and more", function() {
    $('#emma').readmore(20);
    expect($('#emma p:nth-child(1) span.less').html()).toEqual('Emma Woodhouse, handsome,');
    expect($('#emma p:nth-child(1) span.more').html()).toMatch(/^\sclever.*her\.$/);
    expect($('#emma p:nth-child(2)')).toHaveClass('more');
  });


  it("doesn't insert the break point inside inline markup or count characters of which tags consist", function() {
    $('#emma').readmore(535);
    expect($('#emma p:nth-child(2) span.more').html()).toMatch(/^\splace\shad/);
  });


  it("inserts a 'see more' link", function() {
    $('#emma').readmore(20);
    expect($('#emma p:nth-child(2)').next()[0]).toHaveClass("expander");
  });


  it("toggles 'expanded' class on the container when the link is clicked", function() {
    $('#emma').readmore(20);
    $('#emma p:nth-child(2)').next('a').trigger("click");
    expect($('#emma')).toHaveClass('expanded');
  });


  it("is smart enough to work with unparagraphed content too", function() {
    var text = $("p", $('#emma')).html();

    $('#emma').empty().html(text);
    $('#emma').readmore(20);
    console.log($('#emma').html());
    expect($('#emma span.less').html()).toEqual('Emma Woodhouse, handsome,');
  });

});
