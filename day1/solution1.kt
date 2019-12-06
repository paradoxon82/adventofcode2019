
fun calcSum(line: String) {

}

fun readFileLineByLineUsingForEachLine(fileName: String) 
  = File(fileName).forEachLine { calcSum(it) }

fun main(args : Array<String>) {
    
    args.size
}