import java.awt.*;
import javax.swing.tree.*;
import javax.swing.*;

public class JTreeLeafNodeDisableTest extends JFrame {
   private TreeNode treeNode;
   private JTree tree;
   public JTreeLeafNodeDisableTest() {
      setTitle("JTreeLeafNodeDisable Test");
      treeNode = new DefaultMutableTreeNode("Country");
      tree = new JTree();
      tree.setModel(new DefaultTreeModel(treeNode));
      tree.setCellRenderer(new CustomDefaultTreeCellRenderer());

      add(tree);
      setSize(400, 300);
      setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
      setLocationRelativeTo(null);
      setVisible(true);
   }
   public static void main(String[] args) {
      new JTreeLeafNodeDisableTest();
   }
   static class CustomDefaultTreeCellRenderer extends DefaultTreeCellRenderer {
      @Override
      public Component getTreeCellRendererComponent(JTree tree, Object value, boolean sel, boolean expanded, boolean leaf, int row, boolean hasFocus) {
         boolean enabled = false;
         sel = enabled;
         hasFocus = enabled;

         Component treeCellRendererComponent = super.getTreeCellRendererComponent(tree, value, sel, expanded, leaf, row, hasFocus);
         treeCellRendererComponent.setEnabled(enabled);
         return treeCellRendererComponent;
      }
   }
}