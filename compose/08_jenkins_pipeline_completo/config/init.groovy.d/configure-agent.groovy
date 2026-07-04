// CUÁNDO SE APLICA ESTE SCRIPT:
//
// - Jenkins ejecuta TODOS los .groovy de $JENKINS_HOME/init.groovy.d/ en
//   CADA arranque del controller (mecanismo "Groovy init scripts"). Por eso
//   este script comprueba "si ya existe, no lo recrees": es idempotente y
//   se re-ejecuta siempre, incluso en un jenkins_home ya inicializado.
//
// - PERO el propio fichero solo se COPIA a $JENKINS_HOME/init.groovy.d/ la
//   PRIMERA vez que ese jenkins_home arranca. El Dockerfile lo deja en
//   /usr/share/jenkins/ref/init.groovy.d/, y el entrypoint oficial de la
//   imagen jenkins/jenkins copia los ficheros de /usr/share/jenkins/ref/ a
//   $JENKINS_HOME solo si el destino NO existe todavía — no sobreescribe.
//   Consecuencia práctica: si editas este script y solo haces
//   `docker compose build` (o incluso `--no-cache`) + relanzar el
//   contenedor, seguirás ejecutando la versión VIEJA que ya quedó copiada
//   en jenkins_home la primera vez. Para que un cambio en este fichero
//   surta efecto hay que arrancar con un jenkins_home limpio:
//     ./100_destroy.sh   (borra jenkins_home)
//     ./00_init.sh
//     ./01_launch.sh
//   (ver memoria de proyecto: "entorno limpio antes de probar cambios en
//   config/" — este mismo problema causó una credencial SSH apuntando a
//   una ruta de fichero obsoleta la primera vez que se escribió esto).
//
// Da de alta DOS agentes SSH:
// - agent1 (jenkins_agent): agente "puro", sin Docker CLI.
// - agent2 (jenkins_agent_docker): mismo mecanismo, pero con Docker CLI +
//   socket del host, para tareas que sí necesiten imágenes Docker desde
//   un agente (no el controller).

import jenkins.model.Jenkins
import hudson.model.Node
import hudson.slaves.DumbSlave
import hudson.slaves.RetentionStrategy
import hudson.plugins.sshslaves.SSHLauncher
import hudson.plugins.sshslaves.verifiers.NonVerifyingKeyVerificationStrategy
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey

def jenkins = Jenkins.get()
def store = SystemCredentialsProvider.getInstance().getStore()

// Closure, no "def metodo(...) {}": un metodo con nombre dentro de un
// script cuyo fichero tiene guion ("configure-agent.groovy") genera un
// nombre de clase interna ilegal en Groovy (ClassFormatError). Una closure
// no tiene este problema.
def ensureAgent = { credId, keyPath, nodeName, host, label, description ->
  def existingCred = store.getCredentials(Domain.global()).find { it.id == credId }
  if (!existingCred) {
    def keySource = new BasicSSHUserPrivateKey.FileOnMasterPrivateKeySource(keyPath)
    def credential = new BasicSSHUserPrivateKey(
      CredentialsScope.GLOBAL, credId, "jenkins", keySource, "", description
    )
    store.addCredentials(Domain.global(), credential)
    println "[configure-agent] Credencial '${credId}' creada."
  } else {
    println "[configure-agent] Credencial '${credId}' ya existía."
  }

  if (jenkins.getNode(nodeName) == null) {
    def launcher = new SSHLauncher(host, 22, credId)
    launcher.setSshHostKeyVerificationStrategy(new NonVerifyingKeyVerificationStrategy())
    def agent = new DumbSlave(nodeName, "/home/jenkins/agent", launcher)
    agent.setNumExecutors(2)
    agent.setLabelString(label)
    agent.setMode(Node.Mode.NORMAL)
    agent.setRetentionStrategy(new RetentionStrategy.Always())
    jenkins.addNode(agent)
    println "[configure-agent] Nodo '${nodeName}' creado."
  } else {
    println "[configure-agent] Nodo '${nodeName}' ya existía."
  }
}

ensureAgent(
  "agent-ssh-key", "/var/jenkins_home/ssh/id_ed25519",
  "agent1", "jenkins_agent", "agent1",
  "Clave SSH del agente jenkins_agent"
)

ensureAgent(
  "agent2-ssh-key", "/var/jenkins_home/ssh/id_ed25519_agent2",
  "agent2", "jenkins_agent_docker", "agent2",
  "Clave SSH del agente jenkins_agent_docker (con Docker)"
)
