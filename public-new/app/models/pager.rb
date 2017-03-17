# container for paging information, to keep it in one place
class Pager < Struct.new( :link, :page, :last_page, :pages, :need_next, :next, :need_prev, :need_last, :prev)
  PAGE_NUMBERS_TO_SHOW = 10
  def initialize(link, page, last_page)
    self.link = link
    self.page = page.to_i || 1
    self.last_page = last_page.to_i
    lower_page = [ (self.page - PAGE_NUMBERS_TO_SHOW / 2), 1].max
    upper_page = [lower_page + PAGE_NUMBERS_TO_SHOW, (last_page.to_i == 1? 1 :  last_page.to_i + 1) ].min
    self.need_prev = (lower_page > 1)
    self.prev = self.page - 1
    self.need_next = (upper_page < last_page.to_i)
    self.need_last = (last_page.to_i + 1 > upper_page )
    self.next = self.page + 1 
    self.pages = Range.new(lower_page, upper_page, true)
  end
  def one_page?
    last_page < 2
  end
  def to_s
    "Link: #{self.link} Page #{self.page} Last Page #{self.last_page} Need Prev? #{self.need_prev} Need Next: #{self.need_next}"
  end
end
