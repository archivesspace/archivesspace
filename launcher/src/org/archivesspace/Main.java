package org.archivesspace;

import org.eclipse.jetty.server.nio.SelectChannelConnector;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.webapp.WebAppContext;
import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.handler.ContextHandlerCollection;

public class Main
{
    public static void main(String[] args) throws Exception
    {
        System.setProperty("org.eclipse.jetty.webapp.LEVEL", "WARN");
        System.setProperty("org.eclipse.jetty.server.handler.LEVEL", "WARN");

        SelectChannelConnector connector = new SelectChannelConnector();
        Server server = new Server();

        int port = 8080;

        if (args.length == 1) {
            port = Integer.valueOf(args[0]);
        }

        connector.setPort(port);

        server.addConnector(connector);
        server.setSendDateHeader(true);

        WebAppContext frontend = new WebAppContext();
        frontend.setServer(server);
        frontend.setContextPath("/");
        frontend.setWar(Main.class.getClassLoader().getResource("frontend").toExternalForm());

        WebAppContext backend = new WebAppContext();
        backend.setServer(server);
        backend.setContextPath("/backend");
        backend.setWar(Main.class.getClassLoader().getResource("backend").toExternalForm());


        ContextHandlerCollection contexts = new ContextHandlerCollection();
        contexts.setHandlers(new Handler[] { backend, frontend });

        server.setHandler(contexts);

        server.start();

        Thread.sleep(3000);

        System.out.println("\n************************************************************");
        System.out.println(" Welcome to ArchivesSpace\n");
        System.out.println(" You can now point your browser to http://localhost:" + port + "/");
        System.out.println("************************************************************\n");

        server.join();
    }
}
