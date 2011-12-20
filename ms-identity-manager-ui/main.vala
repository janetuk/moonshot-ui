using GLib;

public class HelloVala: GLib.Object {
	public static int main (string[] args) {
		stdout.printf ("Hello world!\n");
		
		return 0;
	}
}
