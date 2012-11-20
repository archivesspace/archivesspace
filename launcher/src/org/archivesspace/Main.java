package org.archivesspace;

import org.eclipse.jetty.server.nio.SelectChannelConnector;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.webapp.WebAppContext;
import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.handler.ContextHandlerCollection;

import java.util.UUID;
import org.jruby.Ruby;


class AppConfig
{
    private Ruby runtime;

    public AppConfig()
    {
        runtime = Ruby.getDefaultInstance();

        runtime.evalScriptlet("require 'config-distribution'");
    }

    public String getString(String setting)
    {
        return runtime.evalScriptlet("AppConfig[:" + setting + "]").asJavaString();
    }
}


public class Main
{
    private static Server runServer(int port, String war, String path)
    {
        Server server = new Server();
        server.setSendDateHeader(true);

        SelectChannelConnector connector = new SelectChannelConnector();
        connector.setPort(port);

        server.addConnector(connector);

        WebAppContext context = new WebAppContext();
        context.setServer(server);
        context.setContextPath(path);
        context.setWar(Main.class.getClassLoader().getResource(war).toExternalForm());

        ContextHandlerCollection contexts = new ContextHandlerCollection();
        contexts.setHandlers(new Handler[] { context });

        server.setHandler(contexts);

        return server;
    }


    public static void main(String[] args) throws Exception
    {
        System.setProperty("org.eclipse.jetty.webapp.LEVEL", "WARN");
        System.setProperty("org.eclipse.jetty.server.handler.LEVEL", "WARN");

        int backend_port = 8089;
        int frontend_port = 8080;
        int solr_port = 8090;

        AppConfig config = new AppConfig();

        System.setProperty("solr.data.dir", config.getString("solr_index_directory"));
        System.setProperty("solr.solr.home", config.getString("solr_home_directory"));
        System.setProperty("aspace.config.search_user_secret",
                           UUID.randomUUID().toString());


        if (args.length >= 1) {
            frontend_port = Integer.valueOf(args[0]);
        }

        if (args.length >= 2) {
            backend_port = Integer.valueOf(args[1]);
        }

        if (args.length >= 3) {
            solr_port = Integer.valueOf(args[2]);
        }

        System.setProperty("aspace.config.backend_url", "http://localhost:"
                           + backend_port);

        System.setProperty("aspace.config.frontend_url", "http://localhost:"
                           + frontend_port);

        System.setProperty("aspace.config.solr_url", "http://localhost:"
                           + solr_port);


        Server backend_server = runServer(backend_port, "backend", "/");
        Server frontend_server = runServer(frontend_port, "frontend", "/");
        Server solr_server = runServer(solr_port, "solr", "/");

        solr_server.start();
        backend_server.start();
        frontend_server.start();

        Thread.sleep(3000);

        System.out.println("\n ************************************************************");
        System.out.println("  Welcome to ArchivesSpace!\n");
        System.out.println("  You can now point your browser to http://localhost:" + frontend_port + "/");
        System.out.println(" ************************************************************\n");

        backend_server.join();
        frontend_server.join();
        solr_server.join();
    }
}
