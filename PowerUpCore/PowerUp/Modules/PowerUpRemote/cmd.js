var wsh = new ActiveXObject("WScript.Shell");
var fso = new ActiveXObject("Scripting.FileSystemObject");

//Run the command cmdline
//Return an array as {command ran, return code, StdOut, StdErr}
function cmd(cmdline)
{
    var result = Array();

    //Create temporary files for StdOut and StdErr
    fCommand = fso.GetTempName();
    fPsExec = fso.GetTempName();

    //The full command that will be run.  %COMSPEC% is the full path to cmd.exe.  /c tells cmd to run the following commands
    //This is done because some commands are built into cmd and don't actually have a file (e.g. dir)
    //> or 1> redirects StdOut to a file and 2> redirects StdErr to a file
    result[0] = "%COMSPEC% /c " + cmdline + " >" + fCommand + " 2>" + fPsExec;

    //Run the command, hide the window, wait for it to finish
    result[1] = wsh.Run(result[0], 0, true);

    //Read the two files and save into result
    result[2] = readFile(fCommand);
    result[3] = readFile(fPsExec);
    
    return result;
}

//This reads and then deletes the text files that contain StdOut and StdErr, returning the contents
function readFile(file)
{
    var result = null;
    
    if (fso.FileExists(file))
    {
        if (fso.GetFile(file).Size > 0)
        {
            var otfFile = fso.OpenTextFile(file);
            result = otfFile.ReadAll();
            otfFile.Close();
        }
        
        fso.DeleteFile(file);
    }
    
    return result;
}

//Converts the command-line arguments into a string array
function argsToArray()
{
    var result = new Array();
    var arg;
    
    //Loop through the arguments
    for (var i = 0; i < WScript.Arguments.length; i++)
    {
        arg = WScript.Arguments(i);

        if (arg.indexOf(" ") >= 0) //The argument has spaces
        {
            arg = "\"" + arg + "\""; //Add quotes around it
        }

        //Add this argument to the end of the result array
        result.push(arg);
    }
    
    return result;
}

function getWithMaskedPassword(text) {
   if (text== null) { return ""; };
   return text.replace(/-p \S+ /, "-p *********** ");
}

//Convert arguments to array then join items into a string separated by a space
var result = cmd(argsToArray().join(" "));

//Show the run summary
WScript.Echo("Ran command: " + getWithMaskedPassword(result[0]));
WScript.Echo("Return code: " + result[1]);
WScript.Echo("---------- PsExec ----------\n" + result[3]);
WScript.Echo("---------- Command ---------\n" + result[2]);

//Set the return code so the calling/parent application can process it
WScript.Quit(result[1]);