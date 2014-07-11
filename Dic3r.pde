// by Les Hall
// started Thu Jul 10 2014
// 


float maxError = 0.4; // maximum error in millimeters
int pointMax = 32767;
String inFileName = "Bobbin.gcode";
String outFileName = "Bobbin_Dic3d.gcode";
String[] infile;
PVector[] pos = new PVector[pointMax];
PVector[] prevPos = new PVector[pointMax];
int layer = 0;
int point = 0;
int prevPoints = 0;
int totalLines = 0;
int numSmashed = 0;
boolean prevSmashed = false;  // keep from smashing overlapping layers
float debug;
int startLine = 0;
int endLine = 0;


void setup()
{
  // basic setup
  size(256, 128, P3D);
  fill(255);
  stroke(127);
  textAlign(CENTER, CENTER);
  
  // read the input file
  infile = loadStrings(inFileName);
  
  // go thru each line in the file
  for (int line = 0; line < infile.length; line++)
  {
    // parse the line
    String[] tokens = splitTokens(infile[line], " ");
    if (tokens.length > 0)
    {
      if (tokens[0].equals("G1") )
      {
        totalLines++;
        float x = 0;
        float y = 0;
        float z = 0;
        boolean Xcheck = (splitTokens(infile[line], "X").length == 2);
        boolean Ycheck = (splitTokens(infile[line], "Y").length == 2);
        boolean Zcheck = (splitTokens(infile[line], "Z").length == 2);
        if (Zcheck)  // if it's got a z in it
        {
          if (splitTokens(tokens[1], "Z")[0].equals("5") )
          {
            layer = 0;
            point = 0;
          }
          else // z coordinate
          {
            if (layer > 2)
            {
              if (!prevSmashed)
              {
                if (checkMatchedLines())
                {
                  prevSmashed = true;
                  numSmashed++;
                  //print second line;
                  printLayer(startLine, endLine, line);
                }
              }
              else
              {
                prevSmashed = false;
              }
              startLine = endLine;
              endLine = line;
            }
                        
            // save all the points to the prevoius points
            prevPos = new PVector[pointMax];
            arrayCopy(pos, prevPos);
            
            // set up counters
            layer++;
            prevPoints = point;
            point = 0;

            // save new z value
            z = float( splitTokens(tokens[1], "Z")[0] );
          }
        }
        else if (Xcheck)
        {
          x = float( splitTokens(tokens[1], "X")[0] );
          y = float( splitTokens(tokens[2], "Y")[0] );
          
          // save values
          pos[point] = new PVector(x, y, z);
          point++;
        }
      }
    }
  }
  
  // save the output file
  saveStrings(outFileName, infile);
}


void draw()
{
  printText();
}


void printText()
{
  background(0);
  text(nf(totalLines, 0, 0) + " G1 lines\n" + 
    nf(layer, 0, 0) + " layers\n" + 
    nf(numSmashed, 0, 0) + " layers smashed\n" + 
    nf(debug, 0, 6) + " debug",  
    width/2, height/2);
}


boolean checkMatchedLines()
{
  boolean pass = true;
  
  // loop thru the points
  for (int i = 0; i < point; i++)
  {
    // find nearest neighbor
    float minDistance =  1000000;  // begin default
    for (int j = 0; j < prevPoints; j++)
    {
      float distance = pos[i].dist(prevPos[j]);
      if (distance <= minDistance)
        minDistance = distance;
    }
    
    // compare to maxError
    if (minDistance > maxError)
      pass = false;
  }
  
  return pass;
}


void printLayer(int startLine, int endLine, int line)
{
  // comment out first layer
  for (int i=startLine; i<endLine; i++)
  {
    infile[i] = ";" + infile[i];
  }
  
  // double E field on second layer
  for (int i=endLine; i<line; ++i)
  {
    boolean Echeck = (splitTokens(infile[i], "E").length == 2);
    if (Echeck)
    {
      String[] halves = splitTokens(infile[i], "E");
      String[] words = splitTokens(halves[1], " ");
      float e = float(words[0]);
      e *= 2.0;
      words[0] = nf(e, 3, 3);
      halves[1] = join(words, " ");
      String whole = join(halves, "E");
      infile[i] = whole;
    }
  }
}





