module Heatmaps
  attr_accessor :heatmapBrush, :heatmapColors, :gradientMap, :heatmap, :clickmap, :maxValue
  
  def draw_heat(width, height, clicks, click_w, click_h)
    self.maxValue = 0

    # load image data:
    dir = File.dirname(File.expand_path(".", __FILE__))
    self.heatmapColors = loadImage(dir+'/heatmapColors.png')
    self.heatmapBrush = loadImage(dir+'/heatmapBrush.png')
    
    # create empty canvases:
    self.heatmap = createImage(width, height, Processing::App::ARGB);
    self.gradientMap = createImage(width, height, Processing::App::ARGB);
    # load pixel arrays for all relevant images
    heatmapColors.loadPixels();

    clicks.each do |mouseX, mouseY|
      # blit the clickmapBrush onto the (offscreen) clickmap:
      #clickmap.blend(clickmapBrush, 0,0,clickmapBrush.width,clickmapBrush.height,mouseX-clickmapBrush.width/2,mouseY-clickmapBrush.height/2,clickmapBrush.width,clickmapBrush.height,BLEND);

      # blit the clickmapBrush onto the background image in the upper left corner:
      #image(clickmapBrush, mouseX-clickmapBrush.width/2, mouseY-clickmapBrush.height/2);
      
      # render the heatmapBrush into the gradientMap:
      drawToGradient(mouseX, mouseY);
      # update the heatmap from the updated gradientMap:
      updateHeatmap();
    end
  end
  
  
  # Rendering code that blits the heatmapBrush onto the gradientMap, centered at the specified pixel and drawn with additive blending
  
  def drawToGradient(x, y)
    # find the top left corner coordinates on the target image
    startX = x-heatmapBrush.width/2;
    startY = y-heatmapBrush.height/2;
  
    (0...heatmapBrush.height).each do |py|
      (0...heatmapBrush.width).each do |px|
        # for every pixel in the heatmapBrush:
        
        # find the corresponding coordinates on the gradient map:
        hmX = startX+px;
        hmY = startY+py;
        
        #The next if-clause checks if we're out of bounds and skips to the next pixel if so.
        #Note that you'd typically optimize by performing clipping outside of the for loops!
        next if (hmX < 0 || hmY < 0 || hmX >= gradientMap.width || hmY >= gradientMap.height)
        
        # get the color of the heatmapBrush image at the current pixel.
        col = heatmapBrush.pixels[py*heatmapBrush.width+px]; # The py*heatmapBrush.width+px part would normally also be optimized by just incrementing the index.
        col = col & 0xff; # This eliminates any part of the heatmapBrush outside of the blue color channel (0xff is the same as 0x0000ff)
        
        # find the corresponding pixel image on the gradient map:
        gmIndex = hmY*gradientMap.width+hmX;
        
        if (gradientMap.pixels[gmIndex] < 0xffffff-col) # sanity check to make sure the gradient map isn't "saturated" at this pixel. This would take some 65535 clicks on the same pixel to happen. :)
          gradientMap.pixels[gmIndex] += col; # additive blending in our 24-bit world: just add one value to the other.
          if (gradientMap.pixels[gmIndex] > maxValue) # We're keeping track of the maximum pixel value on the gradient map, so that the heatmap image can display relative click densities (scroll down to updateHeatmap() for more)
            self.maxValue = gradientMap.pixels[gmIndex];
          end
        end
      end
    end
    gradientMap.updatePixels();
  end
  
  # Updates the heatmap from the gradient map.
  def updateHeatmap()
    # for all pixels in the gradient:
    (0...gradientMap.pixels.length).each do |i|
      # get the pixel's value. Note that we're not extracting any channels, we're just treating the pixel value as one big integer.
      # cast to float is done to avoid integer division when dividing by the maximum value.
      gmValue = gradientMap.pixels[i].to_f;
      
      # color map the value. gmValue/maxValue normalizes the pixel from 0...1, the rest is just mapping to an index in the heatmapColors data.
      colIndex = ((gmValue/maxValue)*(heatmapColors.pixels.length-1)).to_i;
      col = heatmapColors.pixels[colIndex];
  
      # update the heatmap at the corresponding position
      heatmap.pixels[i] = col;
    end
    # load the updated pixel data into the PImage.
    heatmap.updatePixels();
  end
end 
